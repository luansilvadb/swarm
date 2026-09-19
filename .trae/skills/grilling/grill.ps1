#requires -Version 5.1
<#
  grill — o harness do skill `grilling`.

  Duas faces, um arquivo só:

    CLI   — o condutor conduz o interrogatório por aqui. `next` escolhe a próxima
            pergunta pelo grafo de dependências, `answer` registra a decisão do
            humano, `check` diz o que está torto. A validação roda onde a mutação
            acontece, então o ledger nunca fica malformado em silêncio.

    -Hook — o evento chega pelo stdin e a resposta sai pelo stdout:
              SessionStart -> additionalContext: o estado do interrogatório
              Stop         -> decision: block, enquanto houver pergunta pronta sem
                              ser feita, decisão tomada em nome do humano, ou
                              risco alto sem confirmação explícita.

  Regra de ouro: o harness relata, nunca decide. Quem decide é o humano — e o
  ledger só registra uma decisão com `answer_source: user`.

  O ledger tem duas fases. No interrogatório, o grafo de perguntas fecha. Na execução,
  cada decisão com critério de aceite vira promessa, e `met`/`waive` são a única saída.
  A guarda vale nas duas: ela não pode morrer justamente quando começa a parte cara.

  Em qualquer erro no modo hook, sai calado com código 0: um hook quebrado não
  pode virar ruído no contexto de quem está trabalhando.
#>

param(
  [Parameter(Position = 0)][string]$Cmd = 'status',
  [string]$Plan = '',
  [string]$Id = '',
  [string]$Type = 'choice',
  [string]$Decides = '',
  [string]$Instructions = '',
  [string]$Options = '',
  [string]$Recommended = '',
  [string]$Risk = 'medium',
  [string]$DependsOn = '',
  [string]$Value = '',
  [double]$Confidence = 0,
  [switch]$Confirmed,
  [string]$Reason = '',
  [string]$Ask = '',
  [string]$What = '',
  [string]$Source = '',
  [string]$Why = '',
  [string]$Axis = '',
  [string]$Acceptance = '',
  [string]$Evidence = '',
  [string]$Ledger = '',
  [switch]$Perceived,
  [switch]$Force,
  [switch]$Hook
)

$ErrorActionPreference = 'Stop'
try { [Console]::OutputEncoding = [System.Text.Encoding]::UTF8 } catch { }

# Abaixo deste piso, a decisão não está tomada: está sendo adivinhada. Espelha a
# faixa "low confidence: do not act" do System One.
$script:ConfidenceFloor = 0.5

# Risco alto é o que exige confirmação explícita: o threshold escala com o risco.
$script:RiskRank = @{ 'low' = 1; 'medium' = 2; 'high' = 3 }

$script:Statuses = @('open', 'decided', 'blocked_on', 'cut')
$script:Types = @('choice', 'score', 'noul')

# Eixos de um domínio percebido — o que é julgado olhando, não lendo. O piso existe
# porque o fan-out nasce mais estreito exatamente onde o agente tem menos inventário,
# e é onde alguém vai olhar por dez segundos.
$script:PerceivedAxesFloor = 4
$script:PerceivedReferenceAxis = 'reference'

# Nota durante o fan-out, erro na conclusão: são os achados que dizem que o grafo não
# está fechado. Aqui eles deixam de ser aviso.
$script:ConcludeBlockers = @('perceived-thin', 'perceived-no-reference', 'dup-axis', 'dangling-dependency')

# Uma opção que junta duas coisas não decide nenhuma: é o mesmo defeito do `decides`
# composto, aplicado ao menu — e é como uma decisão de qualidade vira lista de features.
$script:BundledOption = '(?i)\+|\s+e\s+|\s+&\s+'

function Get-Root {
  param($Evt)
  # A ordem é a do Trae: TRAE_PROJECT_DIR é o cwd do hook; CLAUDE_PROJECT_DIR existe
  # por compatibilidade; workspace_roots cobre o workspace com vários projetos.
  if ($env:TRAE_PROJECT_DIR) { return $env:TRAE_PROJECT_DIR }
  if ($env:CLAUDE_PROJECT_DIR) { return $env:CLAUDE_PROJECT_DIR }
  if ($Evt) {
    $roots = @(Get-List $Evt 'workspace_roots')
    if ($roots.Count -gt 0) { return [string]$roots[0] }
    $cwd = Get-Field $Evt 'cwd'
    if ($cwd) { return [string]$cwd }
  }
  return (Get-Location).Path
}

# ------------------------------------------------------ o hook, como o Trae o executa

function Get-GrillCommand {
  # O caminho sai do próprio script: rodar `install` de novo conserta sozinho um
  # caminho que mudou de lugar, sem ninguém editar JSON à mão.
  $exe = if ($env:OS -eq 'Windows_NT') { 'powershell' } else { 'pwsh' }
  return "$exe -NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`" -Hook"
}

function Get-HookConfigPath {
  param([string]$Root)
  if (-not $Root) { $Root = Get-Root }
  return (Join-Path $Root '.trae/hooks.json')
}

function Get-HeartbeatPath {
  param([string]$Root)
  if (-not $Root) { $Root = Get-Root }
  return (Join-Path $Root '.trae/grill-hooks.alive')
}

function Test-GrillGroup {
  param($Group)
  foreach ($h in @(Get-List $Group 'hooks')) {
    if ("$(Get-Field $h 'command')" -match 'grill\.ps1') { return $true }
  }
  return $false
}

function Get-HookHealth {
  param([string]$Root)
  $hb = Get-HeartbeatPath $Root
  if (-not (Test-Path -LiteralPath $hb)) { return $null }
  try { return (Get-Content -LiteralPath $hb -Raw -Encoding UTF8).Trim() } catch { return $null }
}

function Write-Heartbeat {
  # Melhor esforço: em modo sandbox o hook pode não ter permissão de escrita, e isso
  # não pode derrubar nada. O batimento só existe para o `install` poder dizer se o
  # hook está vivo de verdade ou se ninguém habilitou a configuração.
  try {
    $hb = Get-HeartbeatPath $Root
    $dir = Split-Path $hb -Parent
    if (-not (Test-Path -LiteralPath $dir)) { New-Item -ItemType Directory -Force $dir | Out-Null }
    (Get-Date).ToString('s') | Set-Content -LiteralPath $hb -Encoding UTF8
  } catch { }
}

function Invoke-Install {
  param([string]$Root)
  if (-not $Root) { $Root = Get-Root }
  $path = Get-HookConfigPath $Root
  $dir = Split-Path $path -Parent
  if (-not (Test-Path -LiteralPath $dir)) { New-Item -ItemType Directory -Force $dir | Out-Null }

  $lines = @()
  $raw = ''
  if (Test-Path -LiteralPath $path) { $raw = (Get-Content -LiteralPath $path -Raw -Encoding UTF8) }

  $config = $null
  $parseFailed = $false
  if (-not [string]::IsNullOrWhiteSpace($raw)) {
    try { $config = $raw | ConvertFrom-Json } catch {
      Copy-Item -LiteralPath $path -Destination "$path.bak" -Force
      $lines += "o hooks.json existente não era JSON válido — guardei em hooks.json.bak e escrevi um novo"
      $config = $null
      $parseFailed = $true
    }
  }
  if ($null -eq $config) { $config = @{ version = 1; hooks = @{} } }
  if (-not (Get-Field $config 'version')) { Set-Field $config 'version' 1 }
  if (-not (Get-Field $config 'hooks')) { Set-Field $config 'hooks' @{} }

  $hooksObj = Get-Field $config 'hooks'
  $preserved = 0
  # "Já estava em dia" não pode sair de comparar dois JSONs: o serializer do PowerShell
  # 5.1 reordena chaves, e o arquivo seria reescrito a cada install. A pergunta certa é
  # se cada evento nosso tem exatamente um grupo, apontando para este script.
  $wantCmd = Get-GrillCommand
  $current = (-not $parseFailed) -and (-not [string]::IsNullOrWhiteSpace($raw))
  foreach ($ev in @('SessionStart', 'Stop')) {
    $grill = @()
    $kept = @()
    foreach ($g in @(Get-List $hooksObj $ev)) {
      if (Test-GrillGroup $g) { $grill += $g } else { $kept += $g }
    }
    $preserved += $kept.Count
    if ($grill.Count -ne 1) { $current = $false }
    else {
      $inner = @(Get-List $grill[0] 'hooks')
      if ($inner.Count -ne 1) { $current = $false }
      elseif ("$(Get-Field $inner[0] 'command')" -ne $wantCmd) { $current = $false }
      if ($ev -eq 'Stop' -and "$(Get-Field $grill[0] 'loop_limit')" -ne '2') { $current = $false }
    }
    $group = @{ hooks = @(@{ type = 'command'; command = $wantCmd; timeout = 30 }) }
    # O Trae corta o Stop quando loop_count chega em loop_limit: dois avisos bastam, o
    # terceiro deixaria o turno travado sem saída.
    if ($ev -eq 'Stop') { $group['loop_limit'] = 2 }
    Set-Field $hooksObj $ev (@($kept) + @($group))
    $lines += "$ev → $wantCmd"
  }
  $otherEvents = @()
  if ($hooksObj -is [hashtable]) { $otherEvents = @($hooksObj.Keys) }
  else { $otherEvents = @($hooksObj.PSObject.Properties | ForEach-Object { $_.Name }) }
  foreach ($name in $otherEvents) {
    if ($name -notin @('SessionStart', 'Stop')) { $preserved += @(Get-List $hooksObj $name).Count }
  }

  $changed = -not $current
  $backed = $false
  if ($changed) {
    if (Test-Path -LiteralPath $path) {
      Copy-Item -LiteralPath $path -Destination "$path.bak" -Force
      $backed = $true
    }
    ($config | ConvertTo-Json -Depth 12) | Set-Content -LiteralPath "$path.tmp" -Encoding UTF8
    Move-Item -LiteralPath "$path.tmp" -Destination $path -Force
  }

  $hb = Get-HookHealth $Root
  Write-Out "[grill] install — $path"
  if (-not $changed) { Write-Out "  já estava em dia" }
  elseif ($backed) { Write-Out "  escreveu — backup em hooks.json.bak" }
  else { Write-Out "  escreveu" }
  foreach ($l in $lines) { Write-Out "  $l" }
  if ($preserved -gt 0) { Write-Out "  preservados: $preserved grupo(s) de outros hooks" }
  if ($hb) { Write-Out "  hooks vivos: último SessionStart em $hb" }
  else { Write-Out "  os hooks ainda não deram sinal neste projeto — confirme em Settings > Hooks que o hook de projeto está habilitado, e que o modo de execução deixa o comando rodar" }
}

function Get-LedgerPath {
  param([string]$Override)
  if ($Override) {
    if ([System.IO.Path]::IsPathRooted($Override)) { return $Override }
    return (Join-Path (Get-Root) $Override)
  }
  return (Join-Path (Get-Root) '.grill.json')
}

function Get-Field {
  param($Obj, [string]$Name, $Default = $null)
  if ($null -eq $Obj) { return $Default }
  if ($Obj -is [hashtable]) { if ($Obj.ContainsKey($Name)) { return $Obj[$Name] } return $Default }
  if ($Obj.PSObject.Properties.Name -contains $Name) { return $Obj.$Name }
  return $Default
}

# Campos de lista sempre passam por aqui: um `depends_on` vazio, um item só, ou um
# array inteiro chegam iguais do outro lado.
function Get-List {
  param($Obj, [string]$Name)
  $v = Get-Field $Obj $Name
  if ($null -eq $v) { return }
  foreach ($i in @($v)) { if ($null -ne $i -and "$i".Trim() -ne '') { $i } }
}

function Set-Field {
  param($Obj, [string]$Name, $Value)
  if ($Obj -is [hashtable]) { $Obj[$Name] = $Value; return }
  Add-Member -InputObject $Obj -NotePropertyName $Name -NotePropertyValue $Value -Force
}

function New-Finding {
  param([string]$Severity, [string]$Code, [string]$Message)
  [pscustomobject]@{ severity = $Severity; code = $Code; message = $Message }
}

function Read-Ledger {
  param([string]$Path)
  # Nunca lança: um ledger corrompido tem que virar diagnóstico, não um hook quebrado.
  if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) { return $null }
  try { return ((Get-Content -LiteralPath $Path -Raw -Encoding UTF8) | ConvertFrom-Json) } catch { return $null }
}

function Write-Ledger {
  param($L, [string]$Path)
  # Troca atômica, com .bak do estado anterior: o interrogatório inteiro vive neste
  # arquivo, e uma escrita interrompida é o único jeito de perder decisões que só
  # existem aqui.
  $json = $L | ConvertTo-Json -Depth 12
  $json | Set-Content -LiteralPath "$Path.tmp" -Encoding UTF8
  if (Test-Path -LiteralPath $Path -PathType Leaf) { Copy-Item -LiteralPath $Path -Destination "$Path.bak" -Force }
  Move-Item -LiteralPath "$Path.tmp" -Destination $Path -Force
}

function Get-Decisions { param($L) @(Get-Field $L 'decisions') | Where-Object { $_ } }
function Get-Facts { param($L) @(Get-Field $L 'facts') | Where-Object { $_ } }

function Get-DecisionMap {
  param($L)
  $map = @{}
  foreach ($d in (Get-Decisions $L)) { $map[[string](Get-Field $d 'id')] = $d }
  return $map
}

function Get-Resolved {
  param($L)
  $set = @{}
  foreach ($d in (Get-Decisions $L)) {
    $s = [string](Get-Field $d 'status')
    if ($s -eq 'decided' -or $s -eq 'cut') { $set[[string](Get-Field $d 'id')] = $true }
  }
  return $set
}

function Get-Unmet {
  param($L)
  # Depois de `conclude` o ledger não é mais um interrogatório: cada decisão com
  # critério de aceite é uma promessa. Promessa sem evidência não fecha turno.
  $out = @()
  foreach ($d in (Get-Decisions $L)) {
    if ([string](Get-Field $d 'status') -ne 'decided') { continue }
    if (-not (Get-Field $d 'acceptance')) { continue }
    if ((Get-Field $d 'met') -eq $true) { continue }
    if ((Get-Field $d 'waived') -eq $true) { continue }
    $out += $d
  }
  return $out
}

function Get-Ids {
  param($Nodes)
  return (@($Nodes | ForEach-Object { [string](Get-Field $_ 'id') }) -join ', ')
}

# Peel estrutural: marca, passada após passada, o nó cujas dependências já existem e
# já estão marcadas. O que sobrar está dentro de um ciclo — ou pendurado abaixo dele.
function Get-Peeled {
  param($L)
  $nodes = @(Get-Decisions $L)
  $map = Get-DecisionMap $L
  $done = @{}
  $guard = $nodes.Count + 1
  for ($pass = 0; $pass -lt $guard; $pass++) {
    $changed = $false
    foreach ($d in $nodes) {
      $id = [string](Get-Field $d 'id')
      if ($done.ContainsKey($id)) { continue }
      $ok = $true
      foreach ($dep in @(Get-List $d 'depends_on')) {
        $depId = [string]$dep
        if (-not $map.ContainsKey($depId)) { $ok = $false; break }
        if (-not $done.ContainsKey($depId)) { $ok = $false; break }
      }
      if ($ok) { $done[$id] = $true; $changed = $true }
    }
    if (-not $changed) { break }
  }
  return $done
}

function Get-DescendantCount {
  param($L, [string]$Id)
  $nodes = @(Get-Decisions $L)
  $seen = @{}
  $stack = New-Object System.Collections.Stack
  $stack.Push($Id)
  while ($stack.Count -gt 0) {
    $cur = [string]$stack.Pop()
    foreach ($d in $nodes) {
      if (@(Get-List $d 'depends_on') -notcontains $cur) { continue }
      $cid = [string](Get-Field $d 'id')
      if ($seen.ContainsKey($cid)) { continue }
      $seen[$cid] = $true
      $stack.Push($cid)
    }
  }
  return $seen.Count
}

function Test-OnMenu {
  param([string]$T, $Options, [string]$V)
  if ($T -eq 'noul') {
    $n = $V.Trim().ToLowerInvariant()
    if ($n -in @('sim', 'yes', 'true', 'y')) { return 'yes' }
    if ($n -in @('não', 'nao', 'no', 'false', 'n')) { return 'no' }
    return $null
  }
  if ($T -eq 'score') {
    $n = 0
    if (-not [int]::TryParse($V.Trim(), [ref]$n)) { return $null }
    if ($n -lt 0 -or $n -ge @($Options).Count) { return $null }
    return "$n"
  }
  foreach ($o in @($Options)) { if ("$o".Trim() -eq $V.Trim()) { return "$o".Trim() } }
  return $null
}

# --------------------------------------------------------------- validação

function Get-Findings {
  param($L)
  $f = @()
  if ($null -eq $L) { return $f }

  $nodes = @(Get-Decisions $L)
  $facts = @(Get-Facts $L)
  $map = Get-DecisionMap $L
  $peeled = Get-Peeled $L
  $factIds = @{}
  foreach ($x in $facts) {
    $fid = [string](Get-Field $x 'id')
    $factIds[$fid] = $true
    if (-not (Get-Field $x 'source')) {
      $f += (New-Finding 'note' 'fact-no-source' "fato sem origem: $fid — um fato sem fonte é invenção.")
    }
  }

  if (-not (Get-Field $L 'plan')) {
    $f += (New-Finding 'block' 'no-plan' 'o ledger não diz o que está sendo interrogado.')
  }
  if ($nodes.Count -eq 0) {
    $f += (New-Finding 'note' 'no-decisions' 'nenhuma pergunta declarada: faça o fan-out antes de perguntar a primeira.')
  }

  $seen = @{}
  foreach ($d in $nodes) {
    $id = [string](Get-Field $d 'id')
    $type = [string](Get-Field $d 'type')
    $status = [string](Get-Field $d 'status')
    $risk = [string](Get-Field $d 'risk')
    $opts = @(Get-List $d 'options')

    if ($seen.ContainsKey($id)) { $f += (New-Finding 'block' 'dup-id' "id repetido: $id.") } else { $seen[$id] = $true }
    if ($id -eq '') { $f += (New-Finding 'block' 'no-id' 'pergunta sem id.') }

    if ($script:Types -notcontains $type) {
      $f += (New-Finding 'block' 'unknown-type' "$id · tipo inválido: '$type' (choice, score ou noul).")
    } else {
      if ($opts.Count -lt 2) {
        $f += (New-Finding 'block' 'few-options' "$id · $($opts.Count) opção(ões): uma pergunta sem alternativas declaradas não tem resposta para registrar.")
      }
      if (-not (Get-Field $d 'recommended')) {
        $f += (New-Finding 'block' 'no-recommendation' "$id · sem recomendação: uma pergunta sem recomendação terceiriza o trabalho de volta.")
      } elseif ($null -eq (Test-OnMenu $type $opts ([string](Get-Field $d 'recommended')))) {
        $f += (New-Finding 'block' 'off-menu-recommendation' "$id · recomendação '$([string](Get-Field $d 'recommended'))' não está entre as opções declaradas.")
      }
    }

    if (-not (Get-Field $d 'decides')) { $f += (New-Finding 'block' 'no-decides' "$id · sem ``decides``: a pergunta não diz o que está decidindo.") }
    elseif ("$(Get-Field $d 'decides')" -match '(?i)\s+e\s+|\s+and\s+|,') {
      $f += (New-Finding 'note' 'compound-decides' "$id · ``decides`` parece juntar dois julgamentos: decomponha.")
    }
    if (-not (Get-Field $d 'instructions')) { $f += (New-Finding 'block' 'no-instructions' "$id · sem ``instructions``: nada foi perguntado.") }

    if ($script:RiskRank.Keys -notcontains $risk) { $f += (New-Finding 'block' 'bad-risk' "$id · risco inválido: '$risk' (low, medium ou high).") }
    if ($script:Statuses -notcontains $status) { $f += (New-Finding 'block' 'bad-status' "$id · status inválido: '$status'.") }

    $ins = [string](Get-Field $d 'instructions')
    if ($facts.Count -gt 0 -and $ins -notmatch '`[^`]+`') {
      $f += (New-Finding 'note' 'unanchored-question' "$id · a pergunta não referencia nenhum fato do estado entre crases: ela pergunta no vazio.")
    }

    $perceived = (Get-Field $d 'perceived') -eq $true
    foreach ($o in $opts) {
      if ("$o" -notmatch $script:BundledOption) { continue }
      if ($perceived) {
        $f += (New-Finding 'block' 'compound-option' "$id · opção '$o' junta duas coisas num domínio percebido: separadas são duas perguntas — juntas, o agente preenche o meio na hora de codar.")
      } else {
        $f += (New-Finding 'note' 'compound-option' "$id · opção '$o' parece juntar duas coisas: se é uma só, ignore; se não, decomponha.")
      }
    }
    if ($perceived) {
      if (-not [string](Get-Field $d 'axis')) {
        $f += (New-Finding 'block' 'perceived-no-axis' "$id · domínio percebido sem ``axis``: sem eixo, o fan-out conta perguntas em vez de cobrir o que vai ser julgado.")
      }
      if (-not (Get-Field $d 'acceptance')) {
        $f += (New-Finding 'block' 'perceived-no-acceptance' "$id · domínio percebido sem ``acceptance``: sem critério escrito, nada verifica se a entrega é a decisão.")
      }
    }

    foreach ($dep in @(Get-List $d 'depends_on')) {
      if (-not $map.ContainsKey([string]$dep)) {
        $f += (New-Finding 'note' 'dangling-dependency' "$id · depende de '$dep', que não existe (aceitável no fan-out, erro na conclusão).")
      }
    }
    if (-not $peeled.ContainsKey($id) -and @(Get-List $d 'depends_on' | Where-Object { $map.ContainsKey([string]$_) }).Count -gt 0) {
      $f += (New-Finding 'block' 'cycle' "$id · a cadeia de dependências não resolve: há um ciclo.")
    }

    switch ($status) {
      'decided' {
        if (-not (Get-Field $d 'answer')) {
          $f += (New-Finding 'block' 'no-answer' "$id · decidida sem ``answer``.")
        } elseif ($null -eq (Test-OnMenu $type $opts ([string](Get-Field $d 'answer')))) {
          $f += (New-Finding 'block' 'off-menu' "$id · resposta '$([string](Get-Field $d 'answer'))' está fora das opções declaradas. Declare a opção nova — resposta fora do menu nunca é aceita em silêncio.")
        }
        if ("$(Get-Field $d 'answer_source')" -ne 'user') {
          $f += (New-Finding 'block' 'decided-not-user' "$id · decidida sem ``answer_source: user``: o agente decidiu no lugar do humano.")
        }
        $c = [double]($(if (Get-Field $d 'confidence') { Get-Field $d 'confidence' } else { 0 }))
        if ($c -lt $script:ConfidenceFloor) {
          $f += (New-Finding 'block' 'low-confidence' "$id · confiança $c abaixo do piso $($script:ConfidenceFloor): registre como bloqueada ou aberta, não como decidida.")
        }
        if ($risk -eq 'high' -and (Get-Field $d 'confirmed_by_user') -ne $true) {
          $f += (New-Finding 'block' 'risk-unconfirmed' "$id · risco alto sem ``confirmed_by_user``: decisão cara de desfazer exige confirmação explícita.")
        }
        if ((Get-Field $d 'accepted_recommendation') -eq $true -and -not (Get-Field $d 'why')) {
          $f += (New-Finding 'block' 'stamped-no-why' "$id · resposta igual à recomendação, sem ``why``: sem o porquê, o humano assinou o que o agente escreveu — o resultado vira o gosto default dele.")
        }
      }
      'cut' {
        if (-not (Get-Field $d 'cut_reason')) {
          $f += (New-Finding 'block' 'cut-no-reason' "$id · cortada sem ``cut_reason``: um corte sem motivo é uma pergunta esquecida.")
        }
      }
      'blocked_on' {
        if (-not (Get-Field $d 'ask')) {
          $f += (New-Finding 'block' 'blocked-no-ask' "$id · bloqueada sem ``ask``: diga o que só o humano pode responder.")
        }
      }
    }
  }

  # Cobertura do domínio percebido: mede a largura do fan-out onde ele costuma nascer
  # fino, e não só a existência de cada nó.
  $perceivedNodes = @($nodes | Where-Object { (Get-Field $_ 'perceived') -eq $true })
  if ($perceivedNodes.Count -gt 0) {
    $axes = @{}
    foreach ($p in $perceivedNodes) {
      $a = [string](Get-Field $p 'axis')
      if (-not $a) { continue }
      if ($axes.ContainsKey($a)) {
        $f += (New-Finding 'note' 'dup-axis' "eixo '$a' declarado mais de uma vez: dois nós no mesmo eixo são profundidade onde faltava largura.")
      } else { $axes[$a] = $true }
    }
    if (-not $axes.ContainsKey($script:PerceivedReferenceAxis)) {
      $f += (New-Finding 'note' 'perceived-no-reference' "nenhum nó no eixo '$($script:PerceivedReferenceAxis)': o padrão do que é bom não foi nomeado — 'premium' fica valendo o que o agente achar que é.")
    }
    if ($axes.Count -lt $script:PerceivedAxesFloor) {
      $f += (New-Finding 'note' 'perceived-thin' "domínio percebido com $($axes.Count) eixo(s), piso $($script:PerceivedAxesFloor): o fan-out nasceu estreito justamente onde o resultado é julgado olhando.")
    }
  }

  return $f
}

function Format-Findings {
  param($Findings)
  $lines = @()
  foreach ($x in $Findings) {
    $tag = if ($x.severity -eq 'block') { 'BLOQUEIA' } else { 'nota' }
    $lines += "[$tag] $($x.code) — $($x.message)"
  }
  return $lines
}

function Get-NextNode {
  param($L)
  $resolved = Get-Resolved $L
  $ready = @()
  foreach ($d in (Get-Decisions $L)) {
    if ([string](Get-Field $d 'status') -ne 'open') { continue }
    $ok = $true
    foreach ($dep in @(Get-List $d 'depends_on')) {
      if (-not $resolved.ContainsKey([string]$dep)) { $ok = $false; break }
    }
    if ($ok) { $ready += $d }
  }
  if ($ready.Count -eq 0) { return $null }
  $ranked = $ready | ForEach-Object {
    [pscustomobject]@{
      node  = $_
      width = Get-DescendantCount $L ([string](Get-Field $_ 'id'))
      risk  = [int]$script:RiskRank[[string](Get-Field $_ 'risk')]
    }
  }
  return ($ranked | Sort-Object -Property @{ Expression = 'width'; Descending = $true }, @{ Expression = 'risk'; Descending = $true } | Select-Object -First 1).node
}

function Format-Node {
  param($D, [string]$Tag)
  $id = [string](Get-Field $D 'id')
  $out = "[grill] $Tag$id · $([string](Get-Field $D 'type')) · risco $([string](Get-Field $D 'risk'))"
  $out += "`n  decide:      $([string](Get-Field $D 'decides'))"
  $out += "`n  pergunta:    $([string](Get-Field $D 'instructions'))"
  if ((Get-Field $D 'perceived') -eq $true) { $out += "`n  percebido:   eixo $([string](Get-Field $D 'axis'))" }
  if (Get-Field $D 'acceptance') { $out += "`n  aceite:      $([string](Get-Field $D 'acceptance'))" }
  $opts = @(Get-List $D 'options')
  if ($opts.Count -gt 0) {
    $marked = @()
    $i = 0
    foreach ($o in $opts) {
      $label = if ([string](Get-Field $D 'type') -eq 'score') { "[$i] $o" } else { "$o" }
      if ("$(Get-Field $D 'recommended')" -eq "$i" -or "$(Get-Field $D 'recommended')" -eq "$o") { $label = "$label  <- recomendado" }
      $marked += $label
      $i++
    }
    $out += "`n  opções:      " + ($marked -join ' · ')
  } else {
    $out += "`n  opções:      yes · no"
    $out += "`n  recomendado: $([string](Get-Field $D 'recommended'))"
  }
  return $out
}

function Get-Counts {
  param($L)
  $c = @{ open = 0; decided = 0; blocked_on = 0; cut = 0 }
  foreach ($d in (Get-Decisions $L)) {
    $s = [string](Get-Field $d 'status')
    if ($c.ContainsKey($s)) { $c[$s]++ }
  }
  return $c
}

function Write-Out {
  param([string]$Text)
  Write-Output $Text
}

# ------------------------------------------------------------------- CLI

$script:LedgerPath = Get-LedgerPath $Ledger

function Fail-And-Exit {
  param($Findings, [string]$Label = 'nada foi gravado')
  foreach ($line in (Format-Findings $Findings)) { Write-Out "  $line" }
  Write-Out "[grill] $Label"
  exit 1
}

function Save-And-Report {
  param($L)
  Write-Ledger $L $script:LedgerPath
  $blocking = @(Get-Findings $L | Where-Object { $_.severity -eq 'block' })
  $notes = @(Get-Findings $L | Where-Object { $_.severity -ne 'block' })
  foreach ($x in $blocking) { Write-Out "[BLOQUEIA] $($x.code) — $($x.message)" }
  foreach ($x in $notes) { Write-Out "[nota] $($x.code) — $($x.message)" }
  if ($blocking.Count -eq 0) { Write-Out "[grill] ok — $($script:LedgerPath)" }
}

if ($Hook) {
  try {
    $raw = [Console]::In.ReadToEnd()
    if ([string]::IsNullOrWhiteSpace($raw)) { exit 0 }
    # Um BOM na frente do JSON derruba o ConvertFrom-Json — e um hook que morre calado é
    # pior do que um hook ausente: a guarda some sem ninguém perceber.
    $raw = $raw.TrimStart([char]0xFEFF)
    $evt = $raw | ConvertFrom-Json
    $name = $evt.hook_event_name
    $root = Get-Root $evt
    $path = Join-Path $root '.grill.json'
    $cmdLine = "powershell -NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`""

    switch ($name) {

      'SessionStart' {
        $L = Read-Ledger $path
        $ctx = "[grill] Interrogatório com ledger. Comandos: new · fact · add · next · answer · block · cut · met · waive · check · conclude · install · repair (`"$cmdLine`" <cmd>)."
        if ($null -eq $L) {
          $ctx += "`nNenhum ``.grill.json`` no projeto: crie com ``new -Plan `"…`"`` antes da primeira pergunta."
          if (Test-Path -LiteralPath $path -PathType Leaf) {
            $ctx = "[grill] O ledger ($path) existe e não é JSON válido: rode ``repair`` para voltar do backup antes de qualquer pergunta."
          }
        } else {
          $c = Get-Counts $L
          $ctx += "`nLedger em aberto: $(Get-Field $L 'plan')"
          $ctx += "`n  decididas $($c.decided) · abertas $($c.open) · bloqueadas no humano $($c.blocked_on) · cortadas $($c.cut)"
          if (Get-Field $L 'awaiting') { $ctx += "`n  aguardando o humano: $(Get-Field $L 'awaiting')" }
          if ((Get-Field $L 'concluded') -eq $true) {
            $ctx += "`n  concluído: o humano já confirmou o entendimento compartilhado."
            $unmet = @(Get-Unmet $L)
            if ($unmet.Count -gt 0) {
              $ctx += "`n  execução em aberto: $($unmet.Count) critério(s) de aceite sem evidência ($(Get-Ids $unmet)) — enquanto isso o Stop não libera o turno. Cumpra com ``met -Id … -Evidence …``."
            }
          }
          else {
            $n = Get-NextNode $L
            if ($n) { $ctx += "`n  próxima pergunta: $([string](Get-Field $n 'id')) — pergunte só ela, com ``next``." }
          }
        }
        @{ hookSpecificOutput = @{ hookEventName = 'SessionStart'; additionalContext = $ctx } } |
          ConvertTo-Json -Depth 6 -Compress
        Write-Heartbeat $root
        exit 0
      }

      'Stop' {
        $L = Read-Ledger $path
        if ($null -eq $L) {
          if (Test-Path -LiteralPath $path -PathType Leaf) {
            @{ decision = 'block'; reason = "[grill] o ledger ($path) existe e não é JSON válido. Rode ``repair`` para voltar do backup antes de seguir — o interrogatório vive nesse arquivo." } |
              ConvertTo-Json -Depth 6 -Compress
          }
          exit 0
        }

        $blocking = @(Get-Findings $L | Where-Object { $_.severity -eq 'block' })
        $next = $null
        $unasked = $false
        $concluded = (Get-Field $L 'concluded') -eq $true
        if (-not (Get-Field $L 'awaiting') -and -not $concluded) {
          $next = Get-NextNode $L
          if ($next) { $unasked = $true }
        }
        # A guarda não termina no interrogatório. Depois de `conclude`, cada decisão com
        # critério de aceite é uma promessa; o turno não fecha enquanto ela não tiver
        # evidência (`met`) ou a dispensa do humano (`waive`). É aqui que uma UI simples
        # deixa de passar por entrega do que foi decidido.
        $unmet = @()
        if ($concluded) { $unmet = @(Get-Unmet $L) }
        if ($blocking.Count -eq 0 -and -not $unasked -and $unmet.Count -eq 0) { exit 0 }

        $loop = [int]($(if (Get-Field $evt 'loop_count') { Get-Field $evt 'loop_count' } else { 0 }))
        $reason = if ($concluded) { "[grill] a execução não fecha assim." } else { "[grill] o interrogatório não fecha assim." }
        if ($loop -gt 0) { $reason += " (aviso $($loop + 1): o Trae libera o turno quando o limite do hook é atingido, então resolva aqui.)" }
        if ($unasked) { $reason += " Há pergunta pronta sem ser feita: $([string](Get-Field $next 'id')) `"$([string](Get-Field $next 'decides'))`"." }
        if ($blocking.Count -gt 0) { $reason += "`n$($blocking.Count) achado(s) bloqueante(s):" }
        foreach ($x in $blocking) { $reason += "`n  $($x.code) — $($x.message)" }
        if ($unmet.Count -gt 0) {
          $reason += "`n$($unmet.Count) critério(s) de aceite sem evidência — $(Get-Ids $unmet):"
          foreach ($u in $unmet) { $reason += "`n  $([string](Get-Field $u 'id')) — $([string](Get-Field $u 'acceptance'))" }
        }
        $reason += "`nPergunte uma (``$cmdLine next``), registre a resposta (``$cmdLine answer -Id … -Value … -Confidence 0..1``, com ``-Why`` quando a resposta for a recomendação), declare o corte (``$cmdLine cut -Id … -Reason …``), ou — se o humano disser que o entendimento está compartilhado — ``$cmdLine conclude``."
        if ($unmet.Count -gt 0) {
          $reason += "`nCumpra o critério com ``$cmdLine met -Id … -Evidence …``, ou peça a dispensa ao humano e registre com ``$cmdLine waive -Id … -Reason … -Confirmed``."
        }
        @{ decision = 'block'; reason = $reason } | ConvertTo-Json -Depth 6 -Compress
        exit 0
      }

      default { exit 0 }
    }
  } catch {
    exit 0
  }
}

try {
  switch ($Cmd) {

    'new' {
      if (-not $Plan) { Write-Out "[grill] new precisa de -Plan `"o que está sendo interrogado`"."; exit 1 }
      # Plug and play: abrir um interrogatório deixa o guard instalado, em dia, e diz
      # na cara se ele está mesmo rodando.
      Invoke-Install (Get-Root)
      if ((Test-Path -LiteralPath $script:LedgerPath) -and -not $Force) {
        Write-Out "[grill] $($script:LedgerPath) já existe. Use -Force para recomeçar."
        exit 1
      }
      $l = @{
        version   = 1
        plan      = $Plan
        concluded = $false
        awaiting  = ''
        facts     = @()
        decisions = @()
      }
      Write-Ledger $l $script:LedgerPath
      Write-Out "[grill] ledger criado — $($script:LedgerPath)"
      Write-Out "  plano: $Plan"
      Write-Out "  próximo: ``fact`` para o estado, depois ``add`` para cada pergunta candidata (fan-out antes da primeira pergunta)."
      Write-Out "  domínio percebido (o que é julgado olhando): ``add -Perceived -Axis reference|palette|typography|space|layout|motion|states|copy -Acceptance `"…`"``."
      exit 0
    }

    'fact' {
      $l = Read-Ledger $script:LedgerPath
      if ($null -eq $l) { Write-Out "[grill] nenhum ledger. Crie com ``new`` -Plan `"…`"."; exit 1 }
      if (-not $Id -or -not $What) { Write-Out "[grill] fact precisa de -Id e -What (e -Source quando o fato vier do repositório)."; exit 1 }
      foreach ($x in (Get-Facts $l)) {
        if ("$([string](Get-Field $x 'id'))" -eq $Id) { Write-Out "[grill] fato '$Id' já existe."; exit 1 }
      }
      $node = @{ id = $Id; what = $What }
      if ($Source) { $node['source'] = $Source }
      $l.facts = @(Get-Facts $l) + $node
      Save-And-Report $l
      exit 0
    }

    'add' {
      $l = Read-Ledger $script:LedgerPath
      if ($null -eq $l) { Write-Out "[grill] nenhum ledger. Crie com ``new`` -Plan `"…`"."; exit 1 }
      if (-not $Id -or -not $Decides -or -not $Instructions) {
        Write-Out "[grill] add precisa de -Id, -Decides e -Instructions (e -Options / -Recommended / -Risk)."
        exit 1
      }
      foreach ($d in (Get-Decisions $l)) {
        if ("$([string](Get-Field $d 'id'))" -eq $Id) { Write-Out "[grill] pergunta '$Id' já existe."; exit 1 }
      }
      $opts = @()
      if ($Type -eq 'noul') {
        $opts = @('yes', 'no')
      } else {
        $opts = @($Options -split ',' | ForEach-Object { $_.Trim() } | Where-Object { $_ })
        if ($opts.Count -lt 2) { Write-Out "[grill] add -Type $Type precisa de -Options `"a,b`" com pelo menos duas."; exit 1 }
      }
      if ($null -eq (Test-OnMenu $Type $opts $Recommended)) {
        Write-Out "[grill] -Recommended '$Recommended' não está entre as opções ($($opts -join ' · ')). Fora do menu não entra."
        exit 1
      }
      # Guardado já normalizado: a pergunta "a resposta é a recomendação?" precisa de uma
      # resposta só, e `sim`/`yes` não podem virar duas.
      $Recommended = [string](Test-OnMenu $Type $opts $Recommended)
      # A validação roda onde a mutação acontece: um nó de domínio percebido declarado
      # torto tem que doer agora, não dez turnos depois na conclusão.
      if ($Perceived) {
        if (-not $Axis) {
          Write-Out "[grill] add -Perceived precisa de -Axis: o nó diz qual eixo do resultado julgado ele decide (reference, palette, typography, space, layout, motion, states, copy)."
          exit 1
        }
        if (-not $Acceptance) {
          Write-Out "[grill] add -Perceived precisa de -Acceptance: sem critério escrito, nada verifica depois se a entrega é a decisão."
          exit 1
        }
        foreach ($o in $opts) {
          if ("$o" -match $script:BundledOption) {
            Write-Out "[grill] a opção '$o' junta duas coisas. Em domínio percebido isso não entra: um nó, um julgamento — decomponha e declare os nós."
            exit 1
          }
        }
      } elseif ($Axis) {
        Write-Out "[grill] -Axis só faz sentido junto com -Perceived."
        exit 1
      }
      $deps = @($DependsOn -split ',' | ForEach-Object { $_.Trim() } | Where-Object { $_ })
      $node = @{
        id           = $Id
        decides      = $Decides
        type         = $Type
        instructions = $Instructions
        options      = $opts
        recommended  = $Recommended
        risk         = $Risk
        status       = 'open'
      }
      if ($deps.Count -gt 0) { $node['depends_on'] = $deps }
      if ($Perceived) { $node['perceived'] = $true; $node['axis'] = $Axis }
      if ($Acceptance) { $node['acceptance'] = $Acceptance }
      $l.decisions = @(Get-Decisions $l) + $node
      Save-And-Report $l
      exit 0
    }

    'next' {
      $l = Read-Ledger $script:LedgerPath
      if ($null -eq $l) { Write-Out "[grill] nenhum ledger. Crie com ``new`` -Plan `"…`"."; exit 1 }
      $n = Get-NextNode $l
      if ($null -eq $n) {
        $c = Get-Counts $l
        Write-Out "[grill] nada pronto para perguntar."
        foreach ($d in (Get-Decisions $l)) {
          $s = [string](Get-Field $d 'status')
          if ($s -eq 'blocked_on') { Write-Out "  bloqueada no humano: $([string](Get-Field $d 'id')) — $([string](Get-Field $d 'ask'))" }
          elseif ($s -eq 'open') { Write-Out "  esperando outra decisão: $([string](Get-Field $d 'id')) (depende de $(@(Get-List $d 'depends_on') -join ', '))" }
        }
        if ($c.decided -gt 0 -and $c.open -eq 0 -and $c.blocked_on -eq 0) {
          Write-Out "  todo o grafo está decidido ou cortado: rode ``check`` e depois ``conclude`` — se o humano confirmar."
        }
        exit 0
      }
      Set-Field $l 'awaiting' ([string](Get-Field $n 'id'))
      Write-Ledger $l $script:LedgerPath
      Write-Out (Format-Node $n 'próxima — ')
      $w = Get-DescendantCount $l ([string](Get-Field $n 'id'))
      if ($w -gt 0) { Write-Out "  desbloqueia: $w pergunta(s)" }
      if (Get-Field $n 'ask') { Write-Out "  já bloqueada no humano: $([string](Get-Field $n 'ask'))" }
      Write-Out "  registre a resposta com: answer -Id $([string](Get-Field $n 'id')) -Value `"…`" -Confidence 0..1"
      exit 0
    }

    'answer' {
      $l = Read-Ledger $script:LedgerPath
      if ($null -eq $l) { Write-Out "[grill] nenhum ledger."; exit 1 }
      if (-not $Id -or -not $Value) { Write-Out "[grill] answer precisa de -Id e -Value."; exit 1 }
      $node = $null
      foreach ($d in (Get-Decisions $l)) { if ("$([string](Get-Field $d 'id'))" -eq $Id) { $node = $d; break } }
      if ($null -eq $node) { Write-Out "[grill] pergunta '$Id' não existe no ledger."; exit 1 }
      $status = [string](Get-Field $node 'status')
      if ($status -eq 'decided') { Write-Out "[grill] '$Id' já está decidida ($([string](Get-Field $node 'answer'))). Uma decisão nova é uma pergunta nova."; exit 1 }
      if ($status -eq 'cut') { Write-Out "[grill] '$Id' foi cortada."; exit 1 }
      $type = [string](Get-Field $node 'type')
      $opts = @(Get-List $node 'options')
      $onMenu = Test-OnMenu $type $opts $Value
      if ($null -eq $onMenu) {
        Write-Out "[grill] '$Value' está fora do menu de '$Id' ($($opts -join ' · '))."
        Write-Out "  O humano respondeu algo que não foi previsto: declare a opção com ``add`` (uma pergunta nova) — nunca registre uma resposta fora do menu."
        exit 1
      }
      # Concordar não é decidir. Quando a resposta é a própria recomendação, o humano não
      # acrescentou informação nenhuma: sem o porquê nas palavras dele, o nó seria uma
      # delegação com a assinatura dele, e o resultado vira o gosto default do agente.
      $rec = [string](Test-OnMenu $type $opts ([string](Get-Field $node 'recommended')))
      $accepted = ("$onMenu" -eq $rec)
      if ($accepted -and -not $Why) {
        Write-Out "[grill] '$Id' fecha na recomendação do agente. Registre o porquê com -Why, nas palavras do humano."
        Write-Out "  Pergunte o critério dele antes de gravar — 'recomendado' sozinho não é uma decisão, é um carimbo."
        Write-Out "  Se ele não tiver critério, o nó não está decidido: ``block -Id $Id -Ask `"…`"`` devolve a pergunta."
        exit 1
      }
      if ([string](Get-Field $node 'risk') -eq 'high' -and -not $Confirmed) {
        Write-Out "[grill] '$Id' é risco alto: só registre com -Confirmed, depois que o humano confirmar explicitamente."
        exit 1
      }
      if ($Confidence -lt $script:ConfidenceFloor) {
        Write-Out "[grill] confiança $Confidence abaixo do piso $($script:ConfidenceFloor): abaixo do piso a decisão não está tomada, está sendo adivinhada."
        Write-Out "  Use ``block -Id $Id -Ask `"…`"`` para devolver a pergunta ao humano."
        exit 1
      }
      Set-Field $node 'answer' $onMenu
      Set-Field $node 'answer_source' 'user'
      Set-Field $node 'confidence' $Confidence
      Set-Field $node 'confirmed_by_user' ([bool]$Confirmed)
      Set-Field $node 'accepted_recommendation' $accepted
      Set-Field $node 'why' $Why
      Set-Field $node 'status' 'decided'
      if ("$(Get-Field $l 'awaiting')" -eq $Id) { Set-Field $l 'awaiting' '' }
      Write-Out "[grill] $Id = $onMenu  (confiança $Confidence$([string]::Concat($(if ($Confirmed) { ', confirmado pelo humano' } else { '' }))))"
      if ($accepted) { Write-Out "  aceita como recomendada — porquê: $Why" }
      Save-And-Report $l
      exit 0
    }

    'cut' {
      $l = Read-Ledger $script:LedgerPath
      if ($null -eq $l) { Write-Out "[grill] nenhum ledger."; exit 1 }
      $node = $null
      foreach ($d in (Get-Decisions $l)) { if ("$([string](Get-Field $d 'id'))" -eq $Id) { $node = $d; break } }
      if ($null -eq $node) { Write-Out "[grill] pergunta '$Id' não existe no ledger."; exit 1 }
      if (-not $Reason) { Write-Out "[grill] cut precisa de -Reason: um corte sem motivo é uma pergunta esquecida."; exit 1 }
      Set-Field $node 'status' 'cut'
      Set-Field $node 'cut_reason' $Reason
      if ("$(Get-Field $l 'awaiting')" -eq $Id) { Set-Field $l 'awaiting' '' }
      Write-Out "[grill] $Id cortada — $Reason"
      Save-And-Report $l
      exit 0
    }

    'block' {
      $l = Read-Ledger $script:LedgerPath
      if ($null -eq $l) { Write-Out "[grill] nenhum ledger."; exit 1 }
      $node = $null
      foreach ($d in (Get-Decisions $l)) { if ("$([string](Get-Field $d 'id'))" -eq $Id) { $node = $d; break } }
      if ($null -eq $node) { Write-Out "[grill] pergunta '$Id' não existe no ledger."; exit 1 }
      if (-not $Ask) { Write-Out "[grill] block precisa de -Ask: diga o que só o humano pode responder."; exit 1 }
      Set-Field $node 'status' 'blocked_on'
      Set-Field $node 'ask' $Ask
      if ("$(Get-Field $l 'awaiting')" -eq $Id) { Set-Field $l 'awaiting' '' }
      Write-Out "[grill] $Id bloqueada no humano — $Ask"
      Save-And-Report $l
      exit 0
    }

    'met' {
      $l = Read-Ledger $script:LedgerPath
      if ($null -eq $l) { Write-Out "[grill] nenhum ledger."; exit 1 }
      $node = $null
      foreach ($d in (Get-Decisions $l)) { if ("$([string](Get-Field $d 'id'))" -eq $Id) { $node = $d; break } }
      if ($null -eq $node) { Write-Out "[grill] pergunta '$Id' não existe no ledger."; exit 1 }
      if (-not (Get-Field $node 'acceptance')) { Write-Out "[grill] '$Id' não tem critério de aceite — não há o que cumprir aqui."; exit 1 }
      # Evidência sem origem é invenção: a mesma regra do `fact`, aplicada à entrega.
      if (-not $Evidence) {
        Write-Out "[grill] met precisa de -Evidence: aponte onde o critério foi observado — arquivo:linha, URL ou o comando que mostrou."
        exit 1
      }
      Set-Field $node 'met' $true
      Set-Field $node 'evidence' $Evidence
      Set-Field $node 'met_at' ((Get-Date).ToString('s'))
      Write-Out "[grill] $Id cumprido — $([string](Get-Field $node 'acceptance'))"
      Write-Out "  evidência: $Evidence"
      Save-And-Report $l
      exit 0
    }

    'waive' {
      $l = Read-Ledger $script:LedgerPath
      if ($null -eq $l) { Write-Out "[grill] nenhum ledger."; exit 1 }
      $node = $null
      foreach ($d in (Get-Decisions $l)) { if ("$([string](Get-Field $d 'id'))" -eq $Id) { $node = $d; break } }
      if ($null -eq $node) { Write-Out "[grill] pergunta '$Id' não existe no ledger."; exit 1 }
      if (-not (Get-Field $node 'acceptance')) { Write-Out "[grill] '$Id' não tem critério de aceite — não há o que dispensar."; exit 1 }
      if (-not $Reason) { Write-Out "[grill] waive precisa de -Reason: dispensar um critério é rebaixar o que foi acordado, e isso tem motivo."; exit 1 }
      # Quem rebaixa a barra é quem a subiu. O agente não dispensa o critério que ele
      # mesmo escreveu para parecer que entregou.
      if (-not $Confirmed) {
        Write-Out "[grill] waive só com -Confirmed, depois que o humano aceitar o rebaixamento explicitamente."
        exit 1
      }
      Set-Field $node 'waived' $true
      Set-Field $node 'waive_reason' $Reason
      Set-Field $node 'waived_by_user' $true
      Write-Out "[grill] $Id dispensado pelo humano — $Reason"
      Save-And-Report $l
      exit 0
    }

    'install' {
      Invoke-Install (Get-Root)
      exit 0
    }

    'repair' {
      $path = $script:LedgerPath
      if ($null -ne (Read-Ledger $path)) { Write-Out "[grill] o ledger está íntegro — nada a reparar."; exit 0 }
      $bak = "$path.bak"
      $restored = Read-Ledger $bak
      if ($null -ne $restored) {
        Copy-Item -LiteralPath $bak -Destination $path -Force
        Write-Out "[grill] ledger restaurado do backup — $path"
        Write-Out "  plano: $(Get-Field $restored 'plan')"
        exit 0
      }
      if (Test-Path -LiteralPath $path -PathType Leaf) {
        Write-Out "[grill] $path existe e não é JSON válido, e não há backup utilizável. Nada foi apagado."
        Write-Out "  Depois de olhar o arquivo, ``new -Plan `"…`" -Force`` começa de novo."
      } else {
        Write-Out "[grill] nenhum ledger em $path."
      }
      exit 0
    }

    'check' {
      $l = Read-Ledger $script:LedgerPath
      if ($null -eq $l) {
        if (Test-Path -LiteralPath $script:LedgerPath -PathType Leaf) {
          Write-Out "[grill] $($script:LedgerPath) existe e não é JSON válido — rode ``repair`` para voltar do backup."
          exit 1
        }
        Write-Out "[grill] nenhum ledger em $($script:LedgerPath)."
        exit 0
      }
      $findings = @(Get-Findings $l)
      $blocking = @($findings | Where-Object { $_.severity -eq 'block' })
      $c = Get-Counts $l
      Write-Out "[grill] $($script:LedgerPath) — plano: $(Get-Field $l 'plan')"
      Write-Out "  decididas $($c.decided) · abertas $($c.open) · bloqueadas no humano $($c.blocked_on) · cortadas $($c.cut)"
      if (Get-Field $l 'awaiting') { Write-Out "  aguardando o humano: $(Get-Field $l 'awaiting')" }
      foreach ($line in (Format-Findings $findings)) { Write-Out "  $line" }
      if ($blocking.Count -eq 0) { Write-Out "[grill] nenhum bloqueio." }
      if ((Get-Field $l 'concluded') -eq $true -and $c.open -gt 0) {
        Write-Out "  [nota] open-at-conclude — $($c.open) pergunta(s) aberta(s) na conclusão: declare como corte ou registre como aceito."
      }
      $unmet = @()
      if ((Get-Field $l 'concluded') -eq $true) {
        $unmet = @(Get-Unmet $l)
        if ($unmet.Count -gt 0) {
          Write-Out "  [nota] execucao-em-aberto — $($unmet.Count) critério(s) de aceite sem evidência ($(Get-Ids $unmet)): enquanto isso, o Stop não libera o turno."
          foreach ($u in $unmet) { Write-Out "     $([string](Get-Field $u 'id')): $([string](Get-Field $u 'acceptance'))" }
        }
      }
      if (-not (Get-HookHealth (Get-Root))) {
        Write-Out "  [nota] hooks-sem-sinal — o Stop não deu sinal neste projeto: rode ``install`` e confirme Settings > Hooks."
      }
      if ($blocking.Count -gt 0 -or $unmet.Count -gt 0) { exit 1 }
      exit 0
    }

    'conclude' {
      $l = Read-Ledger $script:LedgerPath
      if ($null -eq $l) { Write-Out "[grill] nenhum ledger."; exit 1 }
      $findings = @(Get-Findings $l)
      $blocking = @($findings | Where-Object { $_.severity -eq 'block' })
      if ($blocking.Count -gt 0) {
        Write-Out "[grill] não dá para concluir com o ledger torto:"
        Fail-And-Exit $blocking 'nada foi concluído'
      }
      # Nota durante o fan-out, erro na conclusão: um grafo com fan-out fino ou com
      # dependência pendurada não está fechado — e concluir aqui é enactar um plano
      # que já se sabe incompleto.
      $unfinished = @($findings | Where-Object { $script:ConcludeBlockers -contains $_.code })
      if ($unfinished.Count -gt 0) {
        Write-Out "[grill] não dá para concluir com o grafo aberto — isto vira bloqueio na conclusão:"
        Fail-And-Exit $unfinished 'nada foi concluído'
      }
      Set-Field $l 'concluded' $true
      Set-Field $l 'awaiting' ''
      Write-Ledger $l $script:LedgerPath
      $c = Get-Counts $l
      Write-Out "[grill] entendimento compartilhado registrado — $(Get-Field $l 'plan')"
      Write-Out "  decidido:"
      $decidedCount = 0
      $stamped = 0
      foreach ($d in (Get-Decisions $l)) {
        if ([string](Get-Field $d 'status') -ne 'decided') { continue }
        $decidedCount++
        $isStamp = (Get-Field $d 'accepted_recommendation') -eq $true
        if ($isStamp) { $stamped++ }
        $mark = if ($isStamp) { 'recomendado' } else { "recomendado era $(Get-Field $d 'recommended')" }
        Write-Out "   - $([string](Get-Field $d 'id')) = $([string](Get-Field $d 'answer'))  ($mark · confiança $([string](Get-Field $d 'confidence')))"
        if (Get-Field $d 'axis') { Write-Out "     eixo percebido: $([string](Get-Field $d 'axis'))" }
        if (Get-Field $d 'why') { Write-Out "     porquê: $([string](Get-Field $d 'why'))" }
        if (Get-Field $d 'acceptance') { Write-Out "     aceite: $([string](Get-Field $d 'acceptance'))" }
      }
      # O recibo diz de quem é o plano. Um ledger inteiro fechado na recomendação do
      # agente é um plano que o humano assinou sem escrever — e o resultado sai com a
      # cara do gosto default de quem conduziu.
      if ($decidedCount -gt 0) {
        Write-Out "  carimbos: $stamped de $decidedCount decisão(ões) fecharam na recomendação do agente."
        if ($stamped -eq $decidedCount) {
          Write-Out "    todas — o humano não divergiu em nada. Trate o plano como seu, não como dele."
        }
      }
      foreach ($d in (Get-Decisions $l)) {
        if ([string](Get-Field $d 'status') -ne 'cut') { continue }
        Write-Out "  cortado: $([string](Get-Field $d 'id')) — $([string](Get-Field $d 'cut_reason'))"
      }
      if ($c.open -gt 0) { Write-Out "  aberto (não decidido): $(@(Get-Decisions $l | Where-Object { [string](Get-Field $_ 'status') -eq 'open' } | ForEach-Object { [string](Get-Field $_ 'id') }) -join ', ')" }
      if ($c.blocked_on -gt 0) { Write-Out "  bloqueado no humano: $(@(Get-Decisions $l | Where-Object { [string](Get-Field $_ 'status') -eq 'blocked_on' } | ForEach-Object { [string](Get-Field $_ 'id') }) -join ', ')" }
      $unmet = @(Get-Unmet $l)
      if ($unmet.Count -gt 0) {
        Write-Out "  a cumprir — o interrogatório acabou, a guarda não. Cada critério abaixo precisa de ``met -Id … -Evidence …`` (ou ``waive -Id … -Reason `"…`" -Confirmed``, se o humano aceitar o rebaixamento):"
        foreach ($u in $unmet) { Write-Out "   - $([string](Get-Field $u 'id')): $([string](Get-Field $u 'acceptance'))" }
      }
      exit 0
    }

    default {
      $l = Read-Ledger $script:LedgerPath
      Write-Out "[grill] harness do ``grilling`` — ledger: $($script:LedgerPath)"
      if ($null -eq $l -and (Test-Path -LiteralPath $script:LedgerPath -PathType Leaf)) {
        Write-Out "  o ledger existe e não é JSON válido — rode ``repair``."
        exit 1
      }
      if ($null -eq $l) { Write-Out "  (sem ledger: ``new -Plan `"…`"``)"; exit 0 }
      $c = Get-Counts $l
      Write-Out "  plano: $(Get-Field $l 'plan')"
      Write-Out "  decididas $($c.decided) · abertas $($c.open) · bloqueadas no humano $($c.blocked_on) · cortadas $($c.cut)"
      if (Get-Field $l 'awaiting') { Write-Out "  aguardando o humano: $(Get-Field $l 'awaiting')" }
      if ((Get-Field $l 'concluded') -eq $true) {
        Write-Out "  concluído."
        $unmet = @(Get-Unmet $l)
        if ($unmet.Count -gt 0) { Write-Out "  execução em aberto: $($unmet.Count) critério(s) de aceite sem evidência ($(Get-Ids $unmet))" }
      }
      $n = Get-NextNode $l
      if ($n) { Write-Out "  próxima: $([string](Get-Field $n 'id')) (open, pronta — desbloqueia $(Get-DescendantCount $l ([string](Get-Field $n 'id'))))" }
      $blocking = @(Get-Findings $l | Where-Object { $_.severity -eq 'block' })
      $notes = @(Get-Findings $l | Where-Object { $_.severity -ne 'block' })
      Write-Out "  achados: $($blocking.Count) bloqueante(s), $($notes.Count) nota(s) — ``check`` para ver"
      exit 0
    }
  }
} catch {
  Write-Out "[grill] erro: $($_.Exception.Message)"
  exit 1
}

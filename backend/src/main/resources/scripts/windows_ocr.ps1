param([string]$ImagePath)

$ErrorActionPreference = 'Stop'

try {
    Add-Type -AssemblyName System.Runtime.WindowsRuntime
    Add-Type -AssemblyName System.Drawing

    [Windows.Storage.StorageFile, Windows.Storage, ContentType = WindowsRuntime] | Out-Null
    [Windows.Graphics.Imaging.BitmapDecoder, Windows.Foundation, ContentType = WindowsRuntime] | Out-Null
    [Windows.Media.Ocr.OcrEngine, Windows.Foundation, ContentType = WindowsRuntime] | Out-Null
    [Windows.Globalization.Language, Windows.Foundation, ContentType = WindowsRuntime] | Out-Null

    function Await-WinRT($asTaskMethod, $winRtOp, $returnType) {
        $concrete = $asTaskMethod.MakeGenericMethod($returnType)
        $task = $concrete.Invoke($null, @($winRtOp))
        $task.Wait()
        return $task.Result
    }

    $asTaskMethods = [System.WindowsRuntimeSystemExtensions].GetMethods() | Where-Object {
        $_.Name -eq 'AsTask' -and $_.IsGenericMethodDefinition -and $_.GetParameters().Length -eq 1
    }
    $asTaskMethod = $asTaskMethods[0]

    $resolved = (Resolve-Path $ImagePath).Path
    $fileOp = [Windows.Storage.StorageFile]::GetFileFromPathAsync($resolved)
    $storageFile = Await-WinRT $asTaskMethod $fileOp ([Windows.Storage.StorageFile])

    $streamOp = $storageFile.OpenAsync([Windows.Storage.FileAccessMode]::Read)
    $stream = Await-WinRT $asTaskMethod $streamOp ([Windows.Storage.Streams.IRandomAccessStream])

    $decoderOp = [Windows.Graphics.Imaging.BitmapDecoder]::CreateAsync($stream)
    $decoder = Await-WinRT $asTaskMethod $decoderOp ([Windows.Graphics.Imaging.BitmapDecoder])

    $softwareBitmapOp = $decoder.GetSoftwareBitmapAsync()
    $softwareBitmap = Await-WinRT $asTaskMethod $softwareBitmapOp ([Windows.Graphics.Imaging.SoftwareBitmap])

    $engine = [Windows.Media.Ocr.OcrEngine]::TryCreateFromUserProfileLanguages()
    if (-not $engine) {
        $lang = [Windows.Globalization.Language]::new("en-US")
        $engine = [Windows.Media.Ocr.OcrEngine]::TryCreateFromLanguage($lang)
    }

    if ($engine) {
        $ocrResultOp = $engine.RecognizeAsync($softwareBitmap)
        $ocrResult = Await-WinRT $asTaskMethod $ocrResultOp ([Windows.Media.Ocr.OcrResult])

        $words = @()
        foreach ($line in $ocrResult.Lines) {
            foreach ($w in $line.Words) {
                $words += [PSCustomObject]@{
                    Text = $w.Text
                    X = $w.BoundingRect.X
                    Y = $w.BoundingRect.Y
                    Width = $w.BoundingRect.Width
                    Height = $w.BoundingRect.Height
                    MidY = $w.BoundingRect.Y + ($w.BoundingRect.Height / 2.0)
                }
            }
        }

        $sortedWords = $words | Sort-Object MidY
        $lines = @()
        $currentLine = @()
        $currentMidY = -1
        $threshold = 14.0

        foreach ($w in $sortedWords) {
            if ($currentLine.Count -eq 0) {
                $currentLine += $w
                $currentMidY = $w.MidY
            } else {
                if ([Math]::Abs($w.MidY - $currentMidY) -le $threshold) {
                    $currentLine += $w
                    $currentMidY = ($currentLine | Measure-Object -Property MidY -Average).Average
                } else {
                    $lines += ,($currentLine | Sort-Object X)
                    $currentLine = @($w)
                    $currentMidY = $w.MidY
                }
            }
        }
        if ($currentLine.Count -gt 0) {
            $lines += ,($currentLine | Sort-Object X)
        }

        foreach ($l in $lines) {
            $lineText = ($l | ForEach-Object { $_.Text }) -join " "
            Write-Output $lineText
        }
    }

    if ($stream) {
        $stream.Dispose()
    }
} catch {
    Write-Error $_.Exception.Message
    exit 1
}

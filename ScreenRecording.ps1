function New-PSVideoCapture {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true, Position=0)]
        [Alias("path")]
        [string]$OutFolder,

        [Parameter(Mandatory=$false, Position=1)]
        [Alias("FPS")]
        [int]$Framerate = 24,

        [Parameter(Mandatory=$false, Position=2)]
        [string]$VideoName = 'out.mp4',

        [Parameter(Mandatory=$false, Position=3)]
        [string]$FFMpegPath = 'D:\ffmpeg\bin\ffmpeg.exe',

        [switch]$Confirm
    )

    begin {
        Write-Verbose "===========Executing $($MyInvocation.InvocationName)==========="
        Write-Debug "BoundParams: $($MyInvocation.BoundParameters|Out-String)"

        # Load support functions
        . {
            function Out-Screenshot {
                param(
                    [int]$VerStart,
                    [int]$HorStart,
                    [int]$VerEnd,
                    [int]$HorEnd,
                    [string]$Path,
                    [switch]$CaptureCursor
                )

                $bounds = [Drawing.Rectangle]::FromLTRB($HorStart, $VerStart, $HorEnd, $VerEnd)
                $jpg = New-Object System.Drawing.Bitmap $bounds.Width, $bounds.Height
                $graphics = [Drawing.Graphics]::FromImage($jpg)
                $graphics.CopyFromScreen($bounds.Location, [Drawing.Point]::Empty, $bounds.Size)

                if ($CaptureCursor) {
                    $mousePos = [System.Windows.Forms.Cursor]::Position
                    if (($mousePos.X -gt $HorStart) -and ($mousePos.X -lt $HorEnd) -and 
                        ($mousePos.Y -gt $VerStart) -and ($mousePos.Y -lt $VerEnd)) {
                        $x = $mousePos.X - $HorStart
                        $y = $mousePos.Y - $VerStart
                        $pen = [Drawing.Pen]::new([Drawing.Color]::Red, 5)
                        $pen.LineJoin = [Drawing.Drawing2D.LineJoin]::Bevel
                        $graphics.DrawRectangle($pen, $x, $y, 5, 5)
                    }
                }

                $jpg.Save($Path, "JPEG")
                $graphics.Dispose()
                $jpg.Dispose()
            }

            function Get-EvenNumber {
                param([int]$Number)
                return $Number - ($Number % 2)
            }
        }

        Add-Type @"
using System;
using System.Runtime.InteropServices;
public class UserWindows {
    [DllImport("user32.dll")]
    public static extern IntPtr GetForegroundWindow();
}
"@
        Add-Type -AssemblyName System.Drawing
        Add-Type -AssemblyName System.Windows.Forms

        if (!(Test-Path -Path $FFMpegPath)) {
            throw 'FFMpeg path is incorrect'
        }

        $thisWindowHandle = (Get-Process -Name powershell | 
            Where-Object { $_.MainWindowHandle -eq [UserWindows]::GetForegroundWindow() }).MainWindowHandle

        if (Test-Path $OutFolder) {
            Write-Warning 'Output folder already exists. This process will recreate it'
            if (!$Confirm -and $Host.UI.PromptForChoice('Continue', 'Are you sure you wish to continue', 
                @('No', 'Yes'), 1) -ne 1) {
                return
            }
            Remove-Item "$OutFolder\*.jpg" -Force
            Remove-Item "$OutFolder\$VideoName" -Force -ErrorAction SilentlyContinue
        } else {
            New-Item -Path $OutFolder -ItemType Directory -Force | Out-Null
        }

        $msWait = [math]::Floor(1000 / $Framerate)
    }

    process {
        Write-Verbose 'Getting the Window Size'
        Read-Host 'Put mouse cursor in top left corner of capture area and press Enter'
        $start = [System.Windows.Forms.Cursor]::Position
        Read-Host 'Put mouse cursor in bottom right corner of capture area and press Enter'
        $end = [System.Windows.Forms.Cursor]::Position

        $horStart = Get-EvenNumber $start.X
        $verStart = Get-EvenNumber $start.Y
        $horEnd = Get-EvenNumber $end.X
        $verEnd = Get-EvenNumber $end.Y

        Write-Verbose "Box size: X1: $horStart, Y1: $verStart, X2: $horEnd, Y2: $verEnd, Width: $($horEnd - $horStart), Height: $($verEnd - $verStart)"

        if ($Host.UI.PromptForChoice('Continue', "Capture will start 2 seconds after this window loses focus. `nPress CTRL+C to emergency stop", 
            @('No', 'Yes'), 1) -eq 1) {
            $num = 1
            $capture = $false

            while (!$capture) {
                if ([UserWindows]::GetForegroundWindow() -eq $thisWindowHandle) {
                    Start-Sleep -Milliseconds 60
                } else {
                    Start-Sleep -Seconds 2
                    $capture = $true
                }
            }

            while ($capture) {
                if ([UserWindows]::GetForegroundWindow() -eq $thisWindowHandle) {
                    $capture = $false
                } else {
                    $path = "$OutFolder\{0:D5}.jpg" -f $num
                    Out-Screenshot -HorStart $horStart -VerStart $verStart -HorEnd $horEnd -VerEnd $verEnd -Path $path -CaptureCursor
                    $num++
                    Start-Sleep -Milliseconds $msWait
                }
            }
        }
    }

    end {
        Write-Verbose 'Creating video using ffmpeg'
        $args = "-framerate $Framerate -i $OutFolder\%05d.jpg -c:v libx264 -vf fps=25 -pix_fmt yuv420p $OutFolder\$VideoName -y"
        Start-Process -FilePath $FFMpegPath -ArgumentList $args -Wait -NoNewWindow

        Write-Verbose 'Cleaning up jpegs'
        Remove-Item "$OutFolder\*.jpg" -Force
    }
}

# Call the function with parameters
New-PSVideoCapture -OutFolder 'C:\temp\testVid' -Verbose

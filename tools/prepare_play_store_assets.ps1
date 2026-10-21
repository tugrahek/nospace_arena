# Deterministic prepress from existing branding; no generated or retouched gameplay.
[CmdletBinding()]
param()
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing
if (!('StorePngMetadata' -as [type])) {
Add-Type @'
public static class StorePngMetadata {
    public static void AddSrgb(string path) {
        byte[] source = System.IO.File.ReadAllBytes(path);
        byte[] chunk = new byte[] {0,0,0,1,115,82,71,66,0,0,0,0,0};
        uint crc = 0xffffffff;
        for (int i=4;i<9;i++) {
            crc ^= chunk[i];
            for (int bit=0;bit<8;bit++) crc = (crc & 1) != 0 ? (crc >> 1) ^ 0xedb88320 : crc >> 1;
        }
        crc ^= 0xffffffff;
        for (int i=0;i<4;i++) chunk[9+i] = (byte)(crc >> (24-i*8));
        byte[] result = new byte[source.Length + chunk.Length];
        System.Buffer.BlockCopy(source,0,result,0,33);
        System.Buffer.BlockCopy(chunk,0,result,33,chunk.Length);
        System.Buffer.BlockCopy(source,33,result,46,source.Length-33);
        System.IO.File.WriteAllBytes(path,result);
    }
}
'@
}
$repo = Split-Path $PSScriptRoot -Parent
$out = Join-Path $repo 'docs/play-store'
foreach ($folder in @('icon','android-launcher','feature')) {
    New-Item -ItemType Directory -Path (Join-Path $out $folder) -Force | Out-Null
}
[IO.File]::WriteAllText((Join-Path $out '.gdignore'), '')
$logo = [Drawing.Bitmap]::new((Join-Path $repo 'docs/media/logo.png'))
$background = $logo.GetPixel(0,0)
$cyan = [Drawing.ColorTranslator]::FromHtml('#41CEDC')

function New-Canvas([int]$width,[int]$height,[bool]$alpha) {
    $format = if ($alpha) { [Drawing.Imaging.PixelFormat]::Format32bppArgb } else { [Drawing.Imaging.PixelFormat]::Format24bppRgb }
    return [Drawing.Bitmap]::new($width,$height,$format)
}
function New-Graphics([Drawing.Bitmap]$bitmap) {
    $graphics = [Drawing.Graphics]::FromImage($bitmap)
    $graphics.InterpolationMode = [Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
    $graphics.PixelOffsetMode = [Drawing.Drawing2D.PixelOffsetMode]::HighQuality
    $graphics.SmoothingMode = [Drawing.Drawing2D.SmoothingMode]::AntiAlias
    $graphics.TextRenderingHint = [Drawing.Text.TextRenderingHint]::AntiAliasGridFit
    return $graphics
}
function Save-Png([Drawing.Bitmap]$bitmap,[string]$relative) {
    $bitmap.Save((Join-Path $out $relative),[Drawing.Imaging.ImageFormat]::Png)
    [StorePngMetadata]::AddSrgb((Join-Path $out $relative))
}

# Full-square opaque background; Play applies its own outer mask and drop shadow.
$play = New-Canvas 512 512 $true
$g = New-Graphics $play
$g.Clear($background)
$g.DrawImage($logo,[Drawing.Rectangle]::new(0,0,512,512))
$g.Dispose()
Save-Png $play 'icon/play-icon-512.png'
$legacy = New-Canvas 192 192 $false
$g = New-Graphics $legacy
$g.Clear($background)
$g.DrawImage($logo,[Drawing.Rectangle]::new(0,0,192,192))
$g.Dispose()
Save-Png $legacy 'android-launcher/launcher-192.png'

# 108 dp at 4 px/dp. The logo's existing void color becomes the background layer.
$cutout = [Drawing.Bitmap]::new($logo)
$cutout.MakeTransparent($background)
$foreground = New-Canvas 432 432 $true
$g = New-Graphics $foreground
$g.Clear([Drawing.Color]::Transparent)
$g.DrawImage($cutout,[Drawing.Rectangle]::new(96,96,240,240))
$g.Dispose()
Save-Png $foreground 'android-launcher/adaptive-foreground-432.png'
$back = New-Canvas 432 432 $false
$g = New-Graphics $back
$g.Clear($background)
$g.Dispose()
Save-Png $back 'android-launcher/adaptive-background-432.png'
$monochrome = New-Canvas 432 432 $true
for ($y=0;$y -lt 432;$y++) {
    for ($x=0;$x -lt 432;$x++) {
        $alpha=$foreground.GetPixel($x,$y).A
        if ($alpha -gt 0) { $monochrome.SetPixel($x,$y,[Drawing.Color]::FromArgb($alpha,255,255,255)) }
    }
}
Save-Png $monochrome 'android-launcher/adaptive-monochrome-432.png'

# Use the existing wordmark family; fonts are rendered, never redistributed here.
$fonts = [Drawing.Text.PrivateFontCollection]::new()
$fonts.AddFontFile((Join-Path $repo 'assets/fonts/dynapuff/dynapuff-variable.ttf'))
$wordmark = [Drawing.Font]::new($fonts.Families[0],82,[Drawing.FontStyle]::Regular,[Drawing.GraphicsUnit]::Pixel)
$label = [Drawing.Font]::new('Segoe UI',30,[Drawing.FontStyle]::Regular,[Drawing.GraphicsUnit]::Pixel)
$tagline = [Drawing.Font]::new('Segoe UI',22,[Drawing.FontStyle]::Regular,[Drawing.GraphicsUnit]::Pixel)
$whiteBrush = [Drawing.SolidBrush]::new([Drawing.Color]::FromArgb(245,244,255))
$cyanBrush = [Drawing.SolidBrush]::new($cyan)
foreach ($locale in @('en','tr')) {
    $feature = New-Canvas 1024 500 $false
    $g = New-Graphics $feature
    $g.Clear($background)
    $g.DrawImage($logo,[Drawing.Rectangle]::new(64,126,248,248))
    $g.DrawString('NoSpace',$wordmark,$whiteBrush,[Drawing.PointF]::new(370,139))
    $g.DrawString('Arena',$label,$cyanBrush,[Drawing.PointF]::new(376,239))
    # Explicit Unicode characters keep Windows PowerShell 5.1 independent of file encoding.
    $text = if ($locale -eq 'en') { 'Draw a line. Take the void.' } else {
        [string][char]0x00C7 + 'izgiyi kapat. Alan' + [char]0x0131 + ' ele ge' + [char]0x00E7 + 'ir.'
    }
    $g.DrawString($text,$tagline,$whiteBrush,[Drawing.PointF]::new(376,309))
    $g.Dispose()
    Save-Png $feature "feature/feature-$locale-1024x500.draft.png"
    $feature.Dispose()
}

# Review-only mask previews; never upload these as standalone icons.
$review = New-Canvas 864 432 $false
$g = New-Graphics $review
$g.Clear($background)
$circle = [Drawing.Drawing2D.GraphicsPath]::new()
$circle.AddEllipse(0,0,432,432)
$g.SetClip($circle)
$g.DrawImageUnscaled($back,0,0); $g.DrawImageUnscaled($foreground,0,0)
$g.ResetClip()
$g.DrawImageUnscaled($back,432,0); $g.DrawImageUnscaled($foreground,432,0)
$g.Dispose(); $circle.Dispose()
Save-Png $review 'android-launcher/mask-preview.review.png'
foreach ($resource in @($logo,$play,$legacy,$cutout,$foreground,$back,$monochrome,$review,$wordmark,$label,$tagline,$fonts,$whiteBrush,$cyanBrush)) { $resource.Dispose() }
Write-Output 'Prepared Play icon, Android layer drafts, EN/TR feature drafts and mask review.'

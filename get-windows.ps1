# Save this as get-windows.ps1
param(
    [string]$Search = ""
)

Add-Type @"
    using System;
    using System.Runtime.InteropServices;
    using System.Text;
    public class Win32 {
        [DllImport("user32.dll")]
        public static extern bool GetWindowRect(IntPtr hWnd, out RECT lpRect);
        [DllImport("user32.dll")]
        public static extern int GetWindowText(IntPtr hWnd, StringBuilder lpString, int nMaxCount);
        [DllImport("user32.dll")]
        public static extern bool IsWindowVisible(IntPtr hWnd);
        [DllImport("user32.dll")]
        public static extern bool IsIconic(IntPtr hWnd);
        [DllImport("user32.dll")]
        public static extern uint GetWindowThreadProcessId(IntPtr hWnd, out uint lpdwProcessId);
    }
    public struct RECT {
        public int Left, Top, Right, Bottom;
    }
"@

$windows = Get-Process | Where-Object {$_.MainWindowTitle -ne ""} | ForEach-Object {
    $rect = New-Object RECT
    $null = [Win32]::GetWindowRect($_.MainWindowHandle, [ref]$rect)
    $width = $rect.Right - $rect.Left
    $height = $rect.Bottom - $rect.Top
    
    # Only include visible, non-minimized windows with reasonable size
    if ([Win32]::IsWindowVisible($_.MainWindowHandle) -and -not [Win32]::IsIconic($_.MainWindowHandle) -and $width -gt 100 -and $height -gt 100) {
        [PSCustomObject]@{
            Title = $_.MainWindowTitle
            ProcessName = $_.ProcessName
            X = $rect.Left
            Y = $rect.Top
            Width = $width
            Height = $height
            Handle = $_.MainWindowHandle.ToInt64()
        }
    }
}

if ($Search -ne "") {
    $windows = $windows | Where-Object { 
        $_.Title -like "*$Search*" -or $_.ProcessName -like "*$Search*" 
    }
}

$windows | ConvertTo-Json
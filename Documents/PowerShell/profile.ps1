Import-Module PSReadLine

# Menu navigabile con Tab
Set-PSReadLineKeyHandler -Key Tab -Function MenuComplete

# Autocompletamento con frecce
Set-PSReadLineOption -HistorySearchCursorMovesToEnd
Set-PSReadLineKeyHandler -Key UpArrow -Function HistorySearchBackward
Set-PSReadLineKeyHandler -Key DownArrow -Function HistorySearchForward

# Predizioni dalla cronologia
Set-PSReadLineOption -PredictionSource History
Set-PSReadLineOption -ShowToolTips

#エラー挙動定義
$ErrorActionPreference = "Stop" #エラーが発生した場合にスクリプトを停止する

#定数定義
$RELEASE_HISTORY_URL = "https://www.7-zip.org/history.txt" #7zipのリリース履歴URL
$RELEASE_DESCRIPTION_SEPARATOR_BAR = "-------------------------" #7zipのリリース履歴中にあるタイトル&リリース日付とリリース内容を分ける区切り行内容

#エラースタッククリア
$Error.Clear()

#変数初期設定
$MyPath = $MyInvocation.MyCommand.Path #スクリプトのパス
$MyBaseName = [system.io.path]::GetFileNameWithoutExtension($MyPath) #スクリプトのベース名
$MyParentPath = Split-Path -Parent $MyInvocation.MyCommand.Path #スクリプトの親ディレクトリパス
$MyLogFolderPath = Join-Path -Path $MyParentPath -ChildPath "Log" #ログフォルダパス
$MyLogFilePath = Join-Path -Path $MyLogFolderPath -ChildPath ($MyBaseName + ".log") #ログファイルパス
$MyCommonFolderPath = Join-Path -Path $MyParentPath -ChildPath "Common" #共通関数フォルダパス
$MyCommonFilePath = Join-Path -Path $MyCommonFolderPath -ChildPath "Common.ps1" #共通関数ファイルパス
.$MyCommonFilePath #共通関数読み込み
$MySettingFilePath = Join-Path -Path $MyParentPath -ChildPath "Setting.txt" #設定ファイルパス

#アセンブリ読み込み
Add-Type -AssemblyName System.Windows.Forms

try{
	#ログ出力関数
	function Logger{
		param(
			[string]$Title,
			[ValidateSet(
				"None",
				"Error",
				"Question",
				"Warning",
				"Information"
			)][string]$Level = "Information",
			[string]$Message,
			[string]$LogLevel,
			[bool]$Popup
		)
		if(!$Popup -and ($Level -ne "Question")){
			$Title = ""
		}
		$OutputLevelArray = @()
		switch ($LogLevel){
			"Error"       { $OutputLevelArray = @("Error","Question") }
			"Warning"     { $OutputLevelArray = @("Warning","Error","Question") }
			"Information" { $OutputLevelArray = @("Information","Warning","Error","Question") }
			"None"        { $OutputLevelArray = @("None","Information","Warning","Error","Question") }
		}
		if($Level -in $OutputLevelArray){
			return LoggerEX -Title $Title -Level $Level -Message $Message
		}
	}
	
	#メイン
	Start-Transcript -Path $MyLogFilePath
	Write-Host "7zip-ReleaseListingToolを開始します。" -ForegroundColor Green
	Write-Host "設定ファイルを読み込みます。"
	Invoke-Expression -Command (cat -Path $MySettingFilePath -Raw)
	Write-Host "設定ファイルを読み込みました。"
	Logger -Title "設定ファイル読み込み結果" -Level "None" -Message ("[" + ((cat $MySettingFilePath -Encoding UTF8 | ForEach-Object {if(($_)[0] -eq "`$"){$_ | cfs -Delimiter "#"}} | ForEach-Object {$_.P1.Trim()}) -join ",") + "]") -LogLevel $LogLevel -Popup $Popup
}catch{
	Logger -Title "7zip-ReleaseListingToolの実行中にエラーが発生しました。" -Level "Error" -Message $Error[0].Exception.Message -LogLevel $LogLevel -Popup $true
}finally{
	Stop-Transcript
}
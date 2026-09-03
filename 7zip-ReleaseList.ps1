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

try{
	#共通関数の読み込み関数
	function CommonRead{
		ls $MyCommonFolderPath | ForEach-Object {.$_.FullName}
	}

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

	}
	
	#メイン
	Start-Transcript -Path $MyLogFilePath
	Write-Host "7zip-ReleaseListingToolを開始します。" -ForegroundColor Green
	Write-Host "共通関数を読み込みます。"
	CommonRead
}catch{

}finally{
	Stop-Transcript
}
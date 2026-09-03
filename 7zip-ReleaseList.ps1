#エラー挙動定義
$ErrorActionPreference = "Stop" #エラーが発生した場合にスクリプトを停止する

#定数定義
$RELEASE_HISTORY_URL = "https://www.7-zip.org/history.txt" #7zipのリリース履歴URL
$RELEASE_DESCRIPTION_SEPARATOR_BAR = "-------------------------" #7zipのリリース履歴中にあるタイトル&リリース日付とリリース内容を分ける区切り行内容
$OutFileBaseName = "7zip-ReleaseList" #出力ファイルのベース名

#エラースタッククリア
$Error.Clear()

#変数初期設定
$MyPath = $MyInvocation.MyCommand.Path #スクリプトのパス
$MyBaseName = [system.io.path]::GetFileNameWithoutExtension($MyPath) #スクリプトのベース名
$MyParentPath = Split-Path -Parent $MyInvocation.MyCommand.Path #スクリプトの親ディレクトリパス
$MyOutputFolderPath = Join-Path -Path $MyParentPath -ChildPath "Output" #出力フォルダパス
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
	
	#リリース履歴リストオブジェクト作成
	function ReleaseListObjectReturn{
		param(
			$RequestContent
		)
        $Lines = $RequestContent.Split("`n")
		$DescriptionFlag = $false
        $ReleaseList = New-Object -TypeName System.Collections.ArrayList
		for($LineIndex = 0;$LineIndex -lt $Lines.length;$LineIndex++){
            $Line = $Lines[$LineIndex]
			if($Line.Trim() -eq $RELEASE_DESCRIPTION_SEPARATOR_BAR){
				$ReleaseNameAndDate = $Lines[$LineIndex - 1].Trim()#区切り線の1行前はリリース名と日付の行
                $SpaceCount = 0
                $Version = ""
                $ReleaseType = ""
                $ReleaseTypeVersion = ""
                $TemplateString = ""
                for($Index = 0;$Index -lt $ReleaseNameAndDate.length;$Index++){#リリース名と日付の行を1文字ずつ処理
                    if($SpaceCount -le 3){
                        if($ReleaseNameAndDate[$Index] -eq " "){
                            $SpaceCount ++
                            switch($SpaceCount){
                                1{$Version = $TemplateString}#スペースが1つ目が現れた時点ではバージョンが確定(xx.xx)
                                2{$ReleaseType = $TemplateString}#スペースが2つ目が現れた時点ではリリースタイプが確定(alpha,beta)
                                3{$ReleaseTypeVersion = $TemplateString}#スペースが3つ目が現れた時点ではリリースタイプバージョンが確定(xx)
                            }
                            $TemplateString = ""
                            continue
                        }
                    }
                    if($ReleaseNameAndDate[$Index] -eq "-"){
                        $ReleaseDate = $ReleaseNameAndDate[($Index-4)..($ReleaseNameAndDate.length-1)] -join ""#リリース日付は"-"の4文字前から行末まで
                        $ReleaseNameAndDate = ""
                        break
                    }
                    $TemplateString += $ReleaseNameAndDate[$Index]
                }
				$DescriptionFlag = !$DescriptionFlag
				$DescriptionLines = @()
                continue
			}
			if($DescriptionFlag){
				if($Line -eq "`r"){#"`n"でスプリットしているので、行が"`r"のみの行を改行だけの行と判定
					$Descriptionflag = !$Descriptionflag
                    $ReleaseObject = New-Object -TypeName PSCustomObject -Property @{Version = $Version;ReleaseType = $ReleaseType;ReleaseTypeVersion = $ReleaseTypeVersion;ReleaseDate = $ReleaseDate;Description = ($DescriptionLines -join "`r`n")}
					$ReleaseList.Add($ReleaseObject) | Out-Null
                    continue
				}
				$DescriptionLines += $Line
			}
		}
        return $ReleaseList
	}

	#メイン
	Start-Transcript -Path $MyLogFilePath
	Write-Host "7zip-ReleaseListingToolを開始します。" -ForegroundColor Green
	Write-Host "設定ファイルを読み込みます。"
	Invoke-Expression -Command (cat -Path $MySettingFilePath -Raw)
	Write-Host "設定ファイルを読み込みました。"
	
	Logger -Title "設定ファイル読み込み結果" -Level "None" -Message ("[" + ((cat $MySettingFilePath -Encoding UTF8 | ForEach-Object {if(($_)[0] -eq "`$"){$_ | cfs -Delimiter "#"}} | ForEach-Object {$_.P1.Trim()}) -join ",") + "]") -LogLevel $LogLevel -Popup $Popup
	
	$OutputFilePath = Join-Path -Path $MyOutputFolderPath -ChildPath ($OutFileBaseName + "." + $FileExtension)#出力ファイルパス決定

	Logger -Message "7zipのリリース履歴取得実行" -LogLevel $LogLevel -Popup $Popup
	if(($OutType -eq "File") -and ($FileExtension -eq "txt")){#txtファイル出力の場合は、リリース履歴を直接ダウンロードして出力する
		Check-WebRequest -URL $RELEASE_HISTORY_URL
		Simple-WebRequest -URL $RELEASE_HISTORY_URL -OutputPath $OutputFilePath | Out-Null
		Logger -Level "Information" -Message ("7zipのリリース履歴を[" + $OutputFilePath + "]に出力しました。") -LogLevel $LogLevel -Popup $Popup
		return
	}else{
		$RequestObject = Simple-WebRequest -URL $RELEASE_HISTORY_URL
	}
	Logger -Message "7zipのリリース履歴取得完了" -LogLevel $LogLevel -Popup $Popup

	if($OutType -eq "Console"){#コンソール出力の場合は、リリース履歴をコンソールに出力する
		echo $RequestObject.Content
		read-host "Enterを押してください"
		return
	}

	Logger -Message "7zipのリリース履歴出力準備" -LogLevel $LogLevel -Popup $Popup
	$ReleaseListObject = ReleaseListObjectReturn -RequestContent $RequestObject.Content
	Logger -Message "7zipのリリース履歴出力準備完了" -LogLevel $LogLevel -Popup $Popup
}catch{
	Logger -Title "7zip-ReleaseListingToolの実行中にエラーが発生しました。" -Level "Error" -Message $Error[0].Exception.Message -LogLevel $LogLevel -Popup $true
}finally{
	Stop-Transcript
}
function LoggerEX {
	param(
		[string]$Title,
		[ValidateSet(
            "None",
            "Error",
            "Question",
            "Warning",
            "Information"
		)][string]$Level = "Information",
		[string]$Message
	)
	if($Title -ne ""){
		if($Level -eq "Question"){
			LoggerEX -Message ("ポップアップでユーザに" + $Title + "を質問しています")
			$Result = YesNoPopup -Title $Title -Level $Level -Message $Message
			$Message = "ユーザは" + $Title + "に" + $Result + "と回答しました"
		}else{
			OKPopup -Title $Title -Level $Level -Message $Message
		}
	}
	return ("[" + (Get-Date -Format "yyyy/MM/dd HH:mm:ss") + "] " + "[" + [string]::Format("{0,-11}", $Level) + "] " + $Message)
}

function OKPopup{
	param(
		[string]$Title,
		[string]$Level,
		[string]$Message
	)
	[System.Windows.Forms.MessageBox]::Show($Message, $Title, "OK",$Level) | Out-Null
}

function YesNoPopup{
	param(
		[string]$Title,
		[string]$Level,
		[string]$Message
	)
	return [System.Windows.Forms.MessageBox]::Show($Message, $Title, "YesNo",$Level)
}

function Simple-WebRequest{
	param(
		[string]$URL,
		[string]$OutputPath
	)
	if($URL -and $OutputPath){
		Invoke-webRequest -UseBasicParsing -Uri $URL -OutFile $OutputPath | Out-Null
		return $OutputPath
	}else{
		return (Invoke-webRequest -UseBasicParsing -Uri $URL)
	}
}
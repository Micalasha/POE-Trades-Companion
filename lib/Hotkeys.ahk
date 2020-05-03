﻿OnHotkeyPress() {
	global PROGRAM, GuiTrades
	static uniqueNum
	hkPressed := A_ThisHotkey
	uniqueNum := !uniqueNum

	KeyWait, Ctrl, L
	KeyWait, Shift, L
	KeyWait, Alt, L
	keysState := GetKeyStateFunc("Ctrl,LCtrl,RCtrl")
	hkSettings := PROGRAM.HOTKEYS[hkPressed]

	buyMode := GuiTrades.Buy.Is_Tabs ? "Tabs" : "Stack"
	sellMode := GuiTrades.Sell.Is_Tabs ? "Tabs" : "Stack"
	tradesVariables := "%buyer%,%buyerName%,%seller%,%sellerName%,%item%,%itemName%,%price%,%itemPrice%"
	_buyOrSell := "Sell"
	
	Loop % hkSettings.Actions.Count() {
		thisAction := hkSettings.Actions[A_Index]
		actionType := thisAction.Type, actionContent := thisAction.Content

		if (actionType = "APPLY_ACTIONS_TO_BUY_INTERFACE")
			_buyOrSell := "Buy"
		else if (actionType = "APPLY_ACTIONS_TO_SELL_INTERFACE")
			_buyOrSell := "Sell"

		if (actionType != "COPY_ITEM_INFOS") { ; Make sure to only copy item infos after all actions have been done
			if IsContaining(actionContent, tradesVariables) && (GuiTrades[_buyOrSell].Is_Stack)
				TrayNotifications.Show("Action in Stack mode not supported yet.", ""
				. "This action cannot be done because it contains one of the following variables: ""%buyer%,%item%,%price%""."
				. "`n`n" "Stack mode doesn't provide any way to mark a stack as selected currently.", {Fade_Timer:12000})
			else if IsContaining(actionType, "CUSTOM_BUTTON") && (GuiTrades[_buyOrSell].Is_Stack) {
				TrayNotifications.Show("Action in Stack mode not supported yet.", ""
				. "This action cannot be done because it refers to a custom button."
				. "`n`n" "Stack mode doesn't provide any way to mark a stack as selected currently.", {Fade_Timer:12000})
			}
			else
				Do_Action(actionType,  actionContent, _buyOrSell, GuiTrades[_buyOrSell].Active_Tab, uniqueNum)
		}
		else 
			doCopyActionAtEnd := True
	}
	if (doCopyActionAtEnd=True) {
		Sleep 100
		Do_Action("COPY_ITEM_INFOS", "", _buyOrSell, GuiTrades[_buyOrSell].Active_Tab, uniqueNum)
	}

	SetKeyStateFunc(keysState)
}

UpdateHotkeys() {
	DisableHotkeys()
	Sleep 100
	Declare_LocalSettings()
	Sleep 100
	EnableHotkeys()
}

DisableHotkeys() {
	global PROGRAM

	; Disable hotkeys
	for hk, nothing in PROGRAM.HOTKEYS {
		if (hk != "") {
			Hotkey, IfWinActive, ahk_group POEGameGroup
			try {
				Hotkey,% hk, Off
				logsStr := "Disabled hotkey with key """ hk """"
			}
			catch
				logsStr := "Failed to disable hotkey with key """ hk """"
			
			logsAppend .= logsAppend ? "`n" logsStr : logsStr
		}
	}
	Hotkey, IfWinActive

	if (logsAppend)
		AppendToLogs(logsAppend)

	; Reset the arr 
	PROGRAM.HOTKEYS := {}
}

EnableHotkeys() {
	global PROGRAM, POEGameGroup
	programName := PROGRAM.NAME
	Set_TitleMatchMode("RegEx")

	PROGRAM.HOTKEYS := {}

	Loop % PROGRAM.SETTINGS.HOTKEYS.Count() {
		hkIndex := A_Index
		loopedHKSection := PROGRAM.SETTINGS.HOTKEYS[hkIndex]
		loopedHKHotkey := loopedHKSection.Hotkey
		hkSC := TransformKeyStr_ToScanCodeStr(loopedHKHotkey)
		if !(hkSC)
			hkSC := TransformKeyStr_ToVirtualKeyStr(loopedHKHotkey)

		if !(hkSC) {
			logsStr := "Failed to enable hotkey doe to key or sc/vk being empty: key """ hk """ (sc/vk: """ hkSC """)"
			logsAppend .= logsAppend ? "`n" logsStr : logsStr
			Continue
		}
			
		PROGRAM.HOTKEYS[hkSC] := {}
		PROGRAM.HOTKEYS[hkSC].Actions := ObjFullyClone(loopedHKSection.Actions)
		Hotkey, IfWinActive, [a-zA-Z0-9_] ahk_group POEGameGroup
		try {
			Hotkey,% hkSC, OnHotkeyPress, On
			logsStr := "Enabled hotkey with key """ hk """ (sc/vk: """ hkSC """)"
			logsAppend .= logsAppend ? "`n" logsStr : logsStr
		}
		catch {
			logsStr := "Failed to enable hotkey doe to key or sc/vk being empty: key """ hk """ (sc/vk: """ hkSC """)"
			logsAppend .= logsAppend ? "`n" logsStr : logsStr
		}
	}

	if (logsAppend)
		AppendToLogs(logsAppend)
		
	Set_TitleMatchMode()
}

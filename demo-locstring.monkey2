
Namespace jentos.locale.demo.locstring

#Import "<std>"
#Import "<mojo>"
#Import "<mojox>"
#Import "Localization"

#Import "assets/"

Using std..
Using mojo..
Using mojox..
Using jentos.locale..


Function Main()
	
	' we can load single file format
	'Locale.Load( "asset::translation.json","en" )
	
	' or directory format
	Locale.Load( "asset::locale/","en" )
	
	New AppInstance
	
	New MyWindow
	
	App.Run()
End


Class MyWindow Extends Window

	Method New()
		
		Super.New( "",640,480,WindowFlags.Resizable )
		
		' update window title via lambda-binding
		Localized( "app-title",Lambda( t:String )
			Title=t
		End )
		
		_hint=New LocString( "hint" )
		
	End
	
	Method OnRender( canvas:Canvas ) Override
		
		' use LocString as a plain string here
		canvas.DrawText( _hint,20,120 )
		
		If Keyboard.KeyHit( Key.Enter )
			Local lang:=Locale.Lang="en" ? "ru" Else "en"
			Locale.SetLang( lang )
		Endif
		
		RequestRender()
	End
	
	Private
	
	Field _hint:LocString
	
End


Namespace demo.localization.plaintext

#Import "<std>"
#Import "<mojo>"
#Import "<mojox>"
#Import "Localization"

#Import "assets/"

Using std..
Using mojo..
Using mojox..
Using jentos.locale


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
		
		' we update all texts when lang was changed only
		'
		' don't use LocString() in your render loop
		' because it will find string in Map every time
		
		Locale.LangChanged+=Texts.Actualize
		
		' also need to assign texts for current lang
		Texts.Actualize()
		
		' update window title via lambda-binding
		Localized( "app-title",Lambda( t:String )
			Title=t
		End )
		
	End
	
	Method OnRender( canvas:Canvas ) Override
		
		canvas.DrawText( Texts.HelloWorld,20,50 )
		canvas.DrawText( Texts.Hint,20,120 )
		
		If Keyboard.KeyHit( Key.Enter )
			Local lang:=Locale.Lang="en" ? "ru" Else "en"
			Locale.SetLang( lang )
		Endif
		
		RequestRender()
	End
	
	' store all texts of app in special class
	' to simplify access for them
	' use them as read-only members
	'
	Class Texts
		
		Global AppTitle:=""
		Global HelloWorld:=""
		Global Hint:=""
		
		Function Actualize()
			
			AppTitle=Localized( "app-title" )
			HelloWorld=Localized( "hello-world" )
			Hint=Localized( "hint" )
		End
	End
	
End

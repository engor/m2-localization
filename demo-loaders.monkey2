
Namespace demo.localization.loaders

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
	
	Localization.RegisterLoader( "ini",New IniLocLoader )
	
	' NOTE: we load .ini file format
	Locale.Load( "asset::translation.ini","en" )
	
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


Class IniLocLoader Extends LocLoader
	
	Method LoadAll:StringMap<StringMap<String>>( path:String ) Override
	
		Local lines:=LoadString( path,True ).Split( "~n" )
		_data=New StringMap<StringMap<String>>
		Local map:StringMap<String>
		For Local line:=Eachin lines
			line=line.Trim()
			If Not line Continue
			If line.StartsWith( "[" )
				Local group:=line.Slice( 1,line.Length-1 )
				map=New StringMap<String>
				_data[group]=map
			Else
				Local pair:=line.Split( "=" )
				map[pair[0].Trim()]=pair[1].Trim()
			Endif
		Next
		
		_def=_data["info"]["default"]
		_langs=_data["info"]["langs"].Split( "," )
		_format="ini"
		
		Return _data
	End
	
	Method LoadLang:StringMap<String>( path:String,lang:String ) Override
	
		Return LoadAll( path )[lang]
	End
	
End

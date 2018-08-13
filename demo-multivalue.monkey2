
Namespace jentos.locale.demo.multivalue

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
	Locale.Load( "asset::translation-multivalue.ini","en" )
	
	' bind our helper class as a values provider
	RandomMultiLocalizer.PrepareMultiValues( Locale )
	Locale.RegisterValuesProvider( RandomMultiLocalizer.GetRandomValue )
	
	' or directory format
	'Locale.Load( "asset::locale/","en" )
	
	New AppInstance
	
	New MyWindow
	
	App.Run()
End


Class MyWindow Extends Window

	Method New()
		
		Super.New( "",640,480,WindowFlags.Resizable )
		
		' you'll find LocLabel and LocButton below
		'
		Local docker:=New DockingView
		docker.AddView( Localized( "hello-world",New LocLabel ),"top"  )
		docker.AddView( New Label( "" ),"top"  )
		docker.AddView( Localized( "button-remove",New LocButton ),"top"  )
		docker.AddView( New Label( "" ),"top"  )
		
		docker.AddView( Localized( "button-close",New LocButton ),"top"  )
		docker.AddView( New Label( "" ),"top"  )
		
		Local switch:=Localized( "switch-lang",New LocButton )
		switch.Clicked=Lambda()
			' switch lang
			Local lang:=Locale.Lang="en" ? "ru" Else "en"
			Locale.SetLang( lang )
		End
		docker.AddView( switch,"top"  )
		docker.AddView( New Label( "" ),"top"  )
		
		ContentView=docker
		
		' update window title via lambda-binding
		Localized( "app-title", Self.Localize )
		
	End
	
	Method Localize( t:String )
	
		Title=t
	End
	
End


' helper class that we will use to provide random values
' note: use 'extends' to have access to protected _data field
'
Class RandomMultiLocalizer Extends Localization Abstract
	
	Function GetRandomValue:String( key:String,eaten:Bool Ptr )
		' a bit dirty hack to get lang
		Local lang:=Locale.Lang
		' try to find our multivalue
		' and return one random of them
		' or use parent logic
		Local map:=_multiValues[lang]
		If map
			Local stack:=map[key]
			If stack
				' our random value
				eaten[0]=True
				Local index:=RndULong() Mod stack.Length
				Return stack[index]
			Endif
		Endif
		eaten[0]=False
		Return ""
	End
	
	' must call it after loading
	'
	Function PrepareMultiValues( localization:Localization )
		
		' hi, protected field _data :)
		'
		Local data:=localization._data
		
		For Local lang:=Eachin data.Keys
			For Local key:=Eachin data[lang].Keys
				Local value:=data[lang][key]
				If value.StartsWith( SPLITTER )
					' multivalue found
					' create keys for multivalues only
					If Not _multiValues[lang]
						_multiValues[lang]=New StringMap<StringStack>
					Endif
					Local stack:=_multiValues[lang][key]
					If Not stack
						stack=New StringStack
						_multiValues[lang][key]=stack
					Endif
					' parse value
					Local arr:=value.Slice( 1 ).Split( SPLITTER )
					stack.AddAll( arr )
				Endif
			Next
		Next
	End
	
	Private
	
	Const SPLITTER:=";"
	Global _multiValues:=New StringMap<StringMap<StringStack>>
	
End


' implement Localize method to have auto-localization
' when lang will be changed
'
Class LocButton Extends Button
	
	Method New( text:String="",icon:Image=Null )
		Super.New( text,icon )
	End
	
	Method Localize( t:String )
		
		Text=t
	End
End


' implement Localize method to have auto-localization
' when lang will be changed
'
Class LocLabel Extends Label
	
	Method New( text:String="",icon:Image=Null )
		Super.New( text,icon )
	End
	
	Method Localize( t:String )
		
		Text=t
	End
End

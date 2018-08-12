
Namespace jentos.locale.demo.mojox

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
	'
	Locale.Load( "asset::translation.json","en" )
	
	' or directory format
	'
	'Locale.Load( "asset::locale/","en" )
	
	New AppInstance
	
	New MyWindow
	
	App.Run()
End


Class MyWindow Extends Window

	Method New()
		
		Super.New( "",640,480,WindowFlags.Resizable )
		
		' these are mojox Label and Button as is!
		' and they support localization now
		' we use short syntax here: Localized<ViewType>( localizationKey )
		'
		Local docker:=New DockingView
		docker.AddView( Localized<Label>( "hello-world" ),"top"  )
		docker.AddView( New Label( "" ),"top"  )
		docker.AddView( Localized<Button>( "button-remove" ),"top"  )
		docker.AddView( New Label( "" ),"top"  )
		
		docker.AddView( Localized<Button>( "button-close" ),"top"  )
		docker.AddView( New Label( "" ),"top"  )
		
		Local switch:=Localized<Button>( "switch-lang" )
		switch.Clicked=Lambda()
			' switch lang
			Local lang:=Locale.Lang="en" ? "ru" Else "en"
			Locale.SetLang( lang )
		End
		docker.AddView( switch,"top"  )
		docker.AddView( New Label( "" ),"top"  )
		
		ContentView=docker
		
		' update window title via lambda-binding
		Localized( "app-title", Self )
		
	End
	
	Method Localize( t:String )
	
		Title=t
	End
	
End


' implement Localize method to have auto-localization
' when lang will be changed
'
' Note!
' 1. We just add method, no need to write constructor
' 2. No need to add such method into Button because of 
' "Button Extends Label" take it from Label.
' 3. We can bring localization support even into Final classes
' that we can't extends.

Class Label Extension
	
	Method Localize( t:String )
		
		Text=t
	End
End

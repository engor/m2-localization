
Namespace demo.localization.mojox

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
	'
	Locale.Load( "asset::translation.json","en" )
	
	' or directory format
	'
	'Locale.Load( "asset::locale/","en" )
	
	New AppInstance
	
	New MyWindow
	
	App.Run()
End

' note: we implement Localizable here to change window title
'
Class MyWindow Extends Window Implements Localizable

	Method New()
		
		Super.New( "",640,480,WindowFlags.Resizable )
		
		' you'll find LocLabel and LocButton below
		'
		Local docker:=New DockingView
		docker.AddView( Localized( New LocLabel,"hello-world" ),"top"  )
		docker.AddView( New Label( "" ),"top"  )
		docker.AddView( Localized( New LocButton,"button-remove" ),"top"  )
		docker.AddView( New Label( "" ),"top"  )
		
		docker.AddView( Localized( New LocButton,"button-close" ),"top"  )
		docker.AddView( New Label( "" ),"top"  )
		
		Local switch:=Localized( New LocButton,"switch-lang" )
		switch.Clicked=Lambda()
			' switch lang
			Local lang:=Locale.Lang="en" ? "ru" Else "en"
			Locale.SetLang( lang )
		End
		docker.AddView( switch,"top"  )
		docker.AddView( New Label( "" ),"top"  )
		
		ContentView=docker
		
		Localized( Self,"app-title" ) ' bind localization to self too
	End
	
	Method Localize( t:String )
	
		Title=t
	End
	
End

' implement Localizable to have auto-localization
' when lang will be changed
'
Class LocButton Extends Button Implements Localizable
	
	Method New( text:String="",icon:Image=Null )
		Super.New( text,icon )
	End
	
	Method Localize( t:String )
		
		Text=t
	End
End

' implement Localizable to have auto-localization
' when lang will be changed
'
Class LocLabel Extends Label Implements Localizable
	
	Method New( text:String="",icon:Image=Null )
		Super.New( text,icon )
	End
	
	Method Localize( t:String )
		
		Text=t
	End
End

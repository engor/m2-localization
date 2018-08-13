
Namespace jentos.locale

' create global const to use it everywhere
'
Const Locale:=New Localization

#Rem monkeydoc Localization class.
You can load data from file or folder.

File is json format, with keys:
"langs":["ru","en", etc] - array with all supported langs
"default":"en" - default lang
"ru":{},"en":{}, etc - json objects with key-value for each localized string

Folder must contains info.json with json data of
"langs" and "default" like as file above.
and all key-value pairs must be put in separated 
files: en.json, ru.json, etc
#End
Class Localization
	
	#Rem monkeydoc Emitted when lang was changes
	#End
	Field LangChanged:Void()
	
	#Rem monkeydoc Create new instance.
	You can use Locale const all the time and 
	don't create new instances yourself.
	#End
	Method New( defLocale:String="en" )
		
		_def=defLocale
		
		' built-in loaders
		'
		RegisterLoader( "json",New JsonLocLoader )
		RegisterLoader( "ini",New IniLocLoader )
	End
	
	#Rem monkeydoc Load localization data from file or folder.
	#End
	Method Load( path:String,lang:String="" )
		
		_path=path
		
		_lang=lang ?Else _def
		
		Local type:=GetFileType( path )
		
		If type=FileType.File
			LoadFile( path )
		Elseif type=FileType.Directory
			LoadFolder( path )
		Else
			LoadDefaults()
		Endif
		
		LangChanged()
	End
	
	#Rem monkeydoc Set desired current lang.
	#End
	Method SetLang( lang:String,forceReload:Bool=False )
		
		If lang=_lang And Not forceReload Return
		
		_lang=lang ?Else _def
		
		If _allInOneFile
			_cur=_data[_lang]
		Else
			LoadFolder( _path )
		Endif
		
		ReLocalizeAll()
		
		LangChanged()
	End
	
	#Rem monkeydoc Return localized string by key.
	#End
	Operator []:String( key:String )
		
		If Not _providers.Empty
			Local found:=False
			For Local provide:=Eachin _providers
				Local value:=provide( key,Varptr found )
				If found Return value
			Next
		Endif
		If Not _overrides.Empty
			Local items:=_overrides[_lang]
			If items And items.Contains( key )
				Return items[key]
			Endif
		Endif
		
		If _cur.Contains( key ) Return _cur[key]
		
		Local s:="$$"+key+"$$"
		_cur[key]=s
		
		Return s
	End
	
	#Rem monkeydoc Return array of all available langs.
	#End
	Property AllLangs:String[]()
		
		Return _langs
	End
	
	#Rem monkeydoc Return default lang.
	#End
	Property DefaultLang:String()
		
		Return _def
	End
	
	#Rem monkeydoc Return current lang.
	#End
	Property Lang:String()
		
		Return _lang
	End
	
	#Rem monkeydoc Bind any function with signature of 'Void(String)' - store it internally,
	and automatically call when lang will be changed.
	#End
	Method Bind( key:String,func:Void(String) )
	
		func( Self[key] )
	
		Local items:=_bindedFuncs[key]
		If Not items
			items=New Stack<Void(String)>
			_bindedFuncs[key]=items
		Endif
		If Not items.Contains( func )
			items.Add( func )
		Endif
	End
	
	#Rem monkeydoc You can unbind if you want.
	#End
	Method UnBind<T>( target:T ) Where T Implements Localizable
	
		For Local key:=Eachin _bindedItems.Keys
			Local items:=_bindedItems[key]
			Local ok:=items.Remove( target )
			If ok Exit
		Next
	End
	
	#Rem monkeydoc You can unbind if you want.
	#End
	Method UnBind( func:Void(String) )
	
		For Local key:=Eachin _bindedFuncs.Keys
			Local funcs:=_bindedFuncs[key]
			Local ok:=funcs.Remove( func )
			If ok Exit
		Next
	End
	
	#Rem monkeydoc Add value to override data.
	This value will be used instead of loaded from disk.
	#End
	Method AddOverrided( lang:String,key:String,value:String,updateBindings:Bool=True )
		
		Local items:=_overrides[lang]
		If Not items
			items=New StringMap<String>
			_overrides[lang]=items
		Endif
		items[key]=value
		
		If updateBindings
			ReLocalizeKey( key )
		Endif
	End
	
	#Rem monkeydoc Remove value from overrided.
	#End
	Method RemoveOverrided( lang:String,key:String )
	
		Local items:=_overrides[lang]
		If items
			items.Remove( key )
		Endif
	End
	
	#Rem monkeydoc Register loader for desired file format.
	Format is extension of file w/o dot at the beginning ("json","csv").
	Note: every registered loader overrides existing one.
	#End
	Function RegisterLoader( format:String,loader:LocLoader )
		
		_loaders[format]=loader
	End
	
	#Rem monkeydoc Register provider that will be used inside of indexer [] operator.
	Each provider return value for a key, and set 'eaten' flag.
	If eaten flag set to true - localization return value from this provider.
	Else looking at next registered provider.
	And then try to find value inside of itself.
	#End
	Function RegisterValuesProvider( providerFunc:String(key:String,eaten:Bool Ptr) )
		
		_providers.Add( providerFunc )
	End
	
	Protected
	
	Field _data:StringMap<StringMap<String>>
	
	Private
	
	Field _lang:String
	Field _overrides:=New StringMap<StringMap<String>>
	Field _cur:StringMap<String>
	Field _langs:String[]
	Field _def:String
	Field _format:String
	Field _allInOneFile:Bool
	Field _path:String
	Field _bindedFuncs:=New StringMap<Stack<Void(String)>>
	Global _loaders:=New StringMap<LocLoader>
	Global _providers:=New Stack<String(String,Bool Ptr)>
	
	Method LoadFile( path:String )
		
		_format=ExtractExt( path ).Slice( 1 ) ' strip dot
		Local loader:=_loaders[_format]
		Assert( loader<>Null,"Unsupported format - '"+_format+"' !" )
		
		_data=loader.LoadAll( path )
		_langs=loader.Langs
		_def=loader.DefaultLang
		
		_cur=_data[_lang]
		
		_allInOneFile=True
	End
	
	Method LoadFolder( dir:String )
		
		If Not dir.EndsWith( "/" ) Then dir+="/"
		Local jinfo:=JsonObject.Load( dir+"info.json" )
		
		Assert( jinfo<>Null,"Can't load localization config from "+dir+"info.json!" )
		
		Local info:=LocInfo.Parse( jinfo )
		_def=info.def
		_format=info.format
		_langs=info.langs
		
		Local loader:=_loaders[_format]
		Assert( loader<>Null,"Unsupported format - '"+_format+"' !" )
		
		_cur=loader.LoadLang( dir+_lang+"."+_format,_lang )
		
		Assert( _cur<>Null,"Can't load localization data for "+_lang+" lang!" )
		
		_allInOneFile=False
	End
	
	Method LoadDefaults()
		
		' TODO
		
		'_cur=_data.ToObject()
		
		_allInOneFile=True
	End
	
	Method ReLocalizeAll()
		
		For Local key:=Eachin _bindedFuncs.Keys
			Local funcs:=_bindedFuncs[key]
			For Local f:=Eachin funcs
				f( Self[key] )
			Next
		Next
	End
	
	Method ReLocalizeKey( key:String )
	
		Local funcs:=_bindedFuncs[key]
		If funcs
			For Local f:=Eachin funcs
				f( Self[key] )
			Next
		Endif
	End
	
End

#Rem monkeydoc Call Localization.Bind() on target and return itself.
#End
Function Localized<T>:T( key:String,target:T )
	
	Locale.Bind( key,target.Localize )
	
	Return target
End

#Rem monkeydoc Create *New T(string)*, call Localization.Bind() on it and return it.
#End
Function Localized<T>:T( key:String )
	
	Local target:=New T( "" )
	Locale.Bind( key,target.Localize )
	
	Return target
End

#Rem monkeydoc Call Localization.Bind() on func and return itself.
#End
Function Localized:Void(String)( key:String,func:Void(String) )
	
	Locale.Bind( key,func )
	
	Return func
End

#Rem monkeydoc Helper to get localized string.
#End
Function Localized:String( key:String )
	
	Return Locale[key]
End

#Rem monkeydoc Wrapper stored localized string.
You can use it as a plain string thanks to To:String operator.
#End
Class LocString
	
	Method New( key:String )
		
		Locale.Bind( key,Self.Localize )
	End
	
	Method Localize( t:String )
		
		_val=t
	End
	
	Operator To:String()
		
		Return _val
	End
	
	Private
	
	Field _val:String
End


Class LocLoader
	
	Property Format:String()
		Return _format
	End
	
	Property Langs:String[]()
		Return _langs
	End
	
	Property DefaultLang:String()
		Return _def
	End
	
	Property Data:StringMap<StringMap<String>>()
		Return _data
	End
	
	Method LoadAll:StringMap<StringMap<String>>( path:String ) Abstract
	Method LoadLang:StringMap<String>( path:String,lang:String ) Abstract

	Protected
	
	Field _data:StringMap<StringMap<String>>
	Field _def:String
	Field _langs:String[]
	Field _format:String
End

Class LocInfo
	
	Field def:String
	Field langs:String[]
	Field format:String
	
	Function Parse:LocInfo( json:JsonObject )
		
		Local info:=New LocInfo
		info.def=json.GetString( "default" )
		info.format=json.GetString( "format" )
		
		Local jarr:=json.GetArray( "langs" )
		info.langs=New String[jarr.Data.Length]
		For Local i:=0 Until info.langs.Length
			info.langs[i]=jarr.Data[i].ToString()
		Next
		
		Return info
	End
End

Class JsonLocLoader Extends LocLoader
	
	Method LoadAll:StringMap<StringMap<String>>( path:String ) Override
	
		Local data:=JsonObject.Load( path )
	
		Local info:=LocInfo.Parse( data )
		_def=info.def
		_format="json"
		_langs=info.langs
	
		_data=New StringMap<StringMap<String>>
		For Local lang:=Eachin _langs
			_data[lang]=FromJson( data[lang].ToObject() )
		Next
		
		Return _data
	End
	
	Method LoadLang:StringMap<String>( path:String,lang:String ) Override
		
		Local data:=JsonObject.Load( path )
		
		_data=New StringMap<StringMap<String>>
		_data[lang]=FromJson( data[lang].ToObject() )
		
		Return _data[lang]
	End
	
	Private
	
	Method FromJson:StringMap<String>( data:StringMap<JsonValue> )
	
		Local map:=New StringMap<String>
	
		For Local key:=Eachin data.Keys
			map[key]=data[key].ToString()
		Next
	
		Return map
	End
	
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
				map[pair[0].Trim()]=pair[1].Trim().Replace( "\n","~n" )
			Endif
		Next
		
		_def=_data["info"]["default"]
		_langs=_data["info"]["langs"].Split( "," )
		_format="ini"
		
		Return _data
	End
	
	Method LoadLang:StringMap<String>( path:String,lang:String ) Override
		
		Local lines:=LoadString( path,True ).Split( "~n" )
		_data=New StringMap<StringMap<String>>
		Local map:=New StringMap<String>
		For Local line:=Eachin lines
			line=line.Trim()
			If line And Not line.StartsWith( "[" )
				Local pair:=line.Split( "=" )
				map[pair[0].Trim()]=pair[1].Trim().Replace( "\n","~n" )
			Endif
		Next
		
		_data[lang]=map
		
		Return map
	End
	
End


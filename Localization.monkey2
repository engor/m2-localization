
Namespace jentos.locale

' create global const to use it everywhere
'
Const Locale:=New Localization

#Rem monkeydoc Localization class.
You can load data from file of folder.

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
		
		If _cur.Contains( key ) Return _cur[key]
		
		Local s:="$$"+key+"$$"
		_cur[key]=s
		
		Return s
	End
	
	#Rem monkeydoc Return array of all available langs.
	#End
	Property AllLangs:String[]()
		
		Return _all
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
	
	#Rem monkeydoc Bind any 'Localizable' - store it internally,
	and automatically call to their Localize() method when lang will be changed.
	#End
	Method Bind<T>( key:String,target:T ) Where T Implements Localizable
	
		target.Localize( Self[key] )
	
		Local items:=_bindedItems[key]
		If Not items
			items=New Stack<Localizable>
			_bindedItems[key]=items
		Endif
		If Not items.Contains( target )
			items.Add( target )
		Endif
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
	
	Private
	
	Field _lang:String
	Field _data:StringMap<StringMap<String>>
	Field _cur:StringMap<String>
	Field _all:String[]
	Field _def:String
	Field _allInOneFile:Bool
	Field _path:String
	Field _bindedItems:=New StringMap<Stack<Localizable>>
	Field _bindedFuncs:=New StringMap<Stack<Void(String)>>
	
	Method LoadFile( path:String )
		
		Local data:=JsonObject.Load( path )
		
		GrabInfo( data )
		
		_data=New StringMap<StringMap<String>>
		For Local lang:=Eachin _all
			_data[lang]=FromJson( data[lang].ToObject() )
		Next
		
		_cur=_data[_lang]
		
		_allInOneFile=True
	End
	
	Method LoadFolder( dir:String )
		
		If Not dir.EndsWith( "/" ) Then dir+="/"
		Local jinfo:=JsonObject.Load( dir+"info.json" )
		
		Assert( jinfo<>Null,"Can't load localization config from "+dir+"info.json!" )
		
		GrabInfo( jinfo )
		
		_cur=FromJson( JsonObject.Load( dir+_lang+".json" ).ToObject() )
		
		Assert( _cur<>Null,"Can't load localization data for "+_lang+" lang!" )
		
		_allInOneFile=False
	End
	
	Method LoadDefaults()
		
		' TODO
		
		'_cur=_data.ToObject()
		
		_allInOneFile=True
	End
	
	Method GrabInfo( json:JsonObject )
		
		_def=json.GetString( "default" )
		
		Local jarr:=json.GetArray( "langs" )
		_all=New String[jarr.Data.Length]
		For Local i:=0 Until _all.Length
			_all[i]=jarr.Data[i].ToString()
		Next
	End
	
	Method ReLocalizeAll()
		
		For Local key:=Eachin _bindedItems.Keys
			Local items:=_bindedItems[key]
			For Local i:=Eachin items
				i.Localize( Self[key] )
			Next
		Next
		
		For Local key:=Eachin _bindedFuncs.Keys
			Local funcs:=_bindedFuncs[key]
			For Local f:=Eachin funcs
				f( Self[key] )
			Next
		Next
	End
	
	Method FromJson:StringMap<String>( data:StringMap<JsonValue> )
		
		Local map:=New StringMap<String>
		
		For Local key:=Eachin data.Keys
			map[key]=data[key].ToString()
		Next
		
		Return map
	End
	
End

#Rem monkeydoc Interface needed for Localization.Localize() method.
#End
Interface Localizable
	
	Method Localize( t:String )
	
End

#Rem monkeydoc Call Localization.Bind() on target and return itself.
#End
Function Localized<T>:T( key:String,target:T ) Where T Implements Localizable
	
	Locale.Bind( key,target )
	
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
Class LocString Implements Localizable
	
	Method New( key:String )
		
		Locale.Bind( key,Self )
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


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
			_cur=_data[_lang].ToObject()
		Else
			LoadFolder( _path )
		Endif
		
		ReLocalizeAll()
		
		LangChanged()
	End
	
	#Rem monkeydoc Return localized string by key.
	#End
	Operator []:String( key:String )
		
		Return _cur.Contains( key ) ? _cur[key].ToString() Else "$$"+key+"$$"
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
	
	#Rem monkeydoc Localize target and store it internally,
	and automatically re-localize when lang will be changed.
	#End
	Method Localize<T>( target:T,key:String ) Where T Implements Localizable
	
		target.Localize( Self[key] )
	
		Local items:=_linked[key]
		If Not items
			items=New Stack<Localizable>
			_linked[key]=items
		Endif
		If Not items.Contains( target )
			items.Add( target )
		Endif
	End
	
	Private
	
	Field _lang:String
	Field _data:JsonObject
	Field _cur:StringMap<JsonValue>
	Field _all:String[]
	Field _def:String
	Field _allInOneFile:Bool
	Field _path:String
	Field _linked:=New StringMap<Stack<Localizable>>
	
	Method LoadFile( path:String )
		
		_data=JsonObject.Load( path )
		
		GrabInfo( _data )
		
		_cur=_data[_lang].ToObject()
		
		_allInOneFile=True
	End
	
	Method LoadFolder( dir:String )
		
		If Not dir.EndsWith( "/" ) Then dir+="/"
		Local jinfo:=JsonObject.Load( dir+"info.json" )
		
		Assert( jinfo<>Null,"Can't load localization config from "+dir+"info.json!" )
		
		GrabInfo( jinfo )
		
		_data=JsonObject.Load( dir+_lang+".json" )
		
		Assert( _data<>Null,"Can't load localization data for "+_lang+" lang!" )
		
		_cur=_data.ToObject()
		
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
		
		For Local key:=Eachin _linked.Keys
			Local items:=_linked[key]
			For Local i:=Eachin items
				i.Localize( Self[key] )
			Next
		Next
	End
	
	Method UnAssign<T>( withText:T )
	
		'TODO
	
	End
	
End

#Rem monkeydoc Interface needed for Localization.Localize() method.
#End
Interface Localizable
	
	Method Localize( t:String )
	
End

#Rem monkeydoc Call Localization.Localize() on target and return itself.
#End
Function Localized<T>:T( target:T,key:String ) Where T Implements Localizable
	
	Locale.Localize( target,key )
	
	Return target
End

#Rem monkeydoc Helper to get localized string.
#End
Function LocString:String( key:String )
	
	Return Locale[key]
End

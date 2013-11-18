class window.Generator
  constructor: (@salt = "") ->
    @callCount = 0

  getStr: (strSalt = "") ->
    "s#{@salt}#{strSalt}#{@callCount++}"

  getLogin: (strSalt = "") ->
    "#{@getStr strSalt}Login"

  getPassword: (strSalt = "") ->
    "#{@getStr strSalt}Pass"

  getUser: (strSalt = "") ->
    prefix = @getStr strSalt
    new User "#{prefix}Login", "#{prefix}Pass"

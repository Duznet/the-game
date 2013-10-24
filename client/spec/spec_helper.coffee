class window.Generator
  constructor (@salt = "") ->
    @callCount = 0

  getStr: (strSalt = "") ->
    "s#{@salt}#{strSalt}#{@callCount++}"

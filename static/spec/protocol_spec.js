describe("Protocol supporting server", function () {
    var startRes = startTesting();
    if (startRes == null || startRes.result !== "ok") {
        console.log("Testing could not be started");
        document.write("Testing could not be started");
        return;
    };

    it("should respond with 'unknownAction' if it could not recognize action", function () {
        expect(getResponse("asdkhasdasd").result).toBe("unknownAction");
    });

    it("should respond with 'unknownAction' if the action field was empty", function () {
        expect(getResponse("").result).toBe("unknownAction");
    });

    describe("Signup action", function () {

        it("should require login and password", function () {
            expect(signup("signup_test_login", "signup_test_password").result).toBe("ok");
        });

        it("should respond with 'userExists' if this user already exists", function () {
            expect(signup("existing_user", "existing_password").result).toBe("ok");
            expect(signup("existing_user", "existing_password").result).toBe("userExists");
            expect(signup("existing_user", "sdkfjhsdfkjhsdf").result).toBe("userExists");
        });

        it("should respond with 'badLogin' if login was shorter than 4 symbols", function () {
            expect(signup("1", "short_test_password").result).toBe("badLogin");
        });

        it("should respond with 'badLogin' if login was longer than 40 symbols", function () {
            expect(signup("abcdefghijklmnopqrstuvwxyzabcdefghijklmnopqrstuvwxyz", "long_test_password").result)
                .toBe("badLogin");
        });

        it("should respond with 'badPassword' if password was shorter than 4 symbols", function () {
            expect(signup("short_pass_login", "1").result).toBe("badPassword");
        });

        it("should respond with 'badLogin' or 'badPassword' if login and password were incorrect", function () {
            expect(signup("sh", "sh").result).toMatch(/badPassword|badLogin/);
        });
    });

    describe("Signin action", function () {

        it("should respond with sid after the correct signin request", function () {
            var userLogin = "signin_test_login";
            var userPass = "signin_test_pass";
            expect(signup(userLogin, userPass).result).toBe("ok");
            var got = signin(userLogin, userPass);

            expect(got.result).toBe("ok");
            expect(got.sid).toBeDefined();
            expect(got.sid).toMatch(/^[a-zA-z0-9]+$/);
        });

        it("should respond with 'incorrect' if user with requested login doesn't exists", function () {
            var userLogin = "signin_incorrect_l_test_login";
            var userPass = "signin_incorrect_l_test_pass";

            expect(signup(userLogin, userPass).result).toBe("ok");
            expect(signin(userLogin + "no", userPass).result).toBe("incorrect");
            expect(signin(userLogin, userPass + "no").result).toBe("incorrect");
        });

        it("should respond with 'incorrect' if login and password don't match", function () {
            var userLogin = "signin_incorrect_p_test_login";
            var userPass = "signin_incorrect_p_test_pass";

            expect(signup(userLogin, userPass).result).toBe("ok");
            expect(signin(userLogin, userPass + "no").result).toBe("incorrect");
        });

        it("should respond with 'incorrect' if login was empty", function () {
            expect(signin("", "123").result).toBe("incorrect");
        });
    });

    describe("Signout action", function () {

        it("should allow user to sign out using the sid", function () {
            var userLogin = "signout_test_login";
            var userPassword = "singout_test_pass";
            expect(signup(userLogin, userPassword).result).toBe("ok");
            var signinResponse = signin(userLogin, userPassword);
            expect(signinResponse.result).toBe("ok");
            expect(signout(signinResponse.sid).result).toBe("ok");
        });

        it("should respond with 'badSid' if sid was empty" , function () {
            expect(signout("").result).toBe("badSid");
        });

        it("should respond with 'badSid' if sid could not be found" , function () {
            expect(signout("sidNotFound123").result).toBe("badSid");
        });

        it("should respond with 'badSid' if user was not signed in", function () {
            var userLogin = "singed_out_user";
            var userPassword = "signed_out_pass";
            signup(userLogin, userPassword);
            var sid = signin(userLogin, userPassword).sid;
            expect(signout(sid).result).toBe("ok");
            expect(signout(sid).result).toBe("badSid");
        });
    });

    describe("Messages", function () {

        var firstUser = {
            login: "mess_test_login1",
            password: "mess_test_pass1"
        };
        var secondUser = {
            login: "mess_test_login2",
            password: "mess_test_pass2"
        };

        signup(firstUser.login, firstUser.password);
        signup(secondUser.login, secondUser.password);

        beforeEach(function () {
            firstUser.sid = signin(firstUser.login, firstUser.password).sid;
            secondUser.sid = signin(secondUser.login, secondUser.password).sid;
        });


        describe("sendMessage action", function () {

            it("should allow user to send text to chat using sid", function () {
                expect(sendMessage(firstUser.sid, "", "Hello").result).toBe("ok");
            });

            it("should respond with 'badSid' if user with that sid was not found", function () {
                expect(sendMessage("^&%DF&TSDFH", "", "Hello").result).toBe("badSid");
            });
        });

        describe("getMessages action", function () {

            it("should allow user to get messages using sid", function () {

                var firstText = "Hello, second";
                var secondText = "Hi, first";
                expect(sendMessage(firstUser.sid, "", firstText).result).toBe("ok");
                expect(sendMessage(secondUser.sid, "", secondText).result).toBe("ok");

                var getMessagesResponse = getMessages(firstUser.sid, "", 0);
                expect(getMessagesResponse.result).toBe("ok");
                var firstMessage = getMessagesResponse.messages[getMessagesResponse.messages.length - 2];
                var secondMessage = getMessagesResponse.messages[getMessagesResponse.messages.length - 1]

                expect(secondMessage.time).toBeGreaterThan(firstMessage.time);
                var firstAuthor = firstMessage.login == firstUser.login ? firstUser : secondUser;
                var secondAuthor = secondMessage.login == secondUser.login ? secondUser : firstUser;
                expect(firstMessage.login).toBe(firstAuthor.login);
                expect(firstMessage.text).toBe(firstText);
                expect(secondMessage.login).toBe(secondAuthor.login);
                expect(secondMessage.text).toBe(secondText);
            });

            it("should respond with 'badSid' if user with that sid was not found", function () {
                expect(getMessages(firstUser.sid + "#W*&^W#$", "", 0).result).toBe("badSid");
            });

            it("should respond with 'badGame' if game with that id was not found", function () {
                expect(getMessages(firstUser.sid, "#$(*&", 0).result).toBe("badGame");
            });

            it("should respond with 'badSince' if the 'since' timestamp was not cool", function () {
                expect(getMessages(firstUser.sid, "" , "suddenly not time").result).toBe("badSince");
            });
        });
    });

    describe("Map controlling", function () {

        describe("uploadMap action", function () {

            var user = {
                login: "mapUploaderLogin",
                password: "mapUploaderPass"
            };

            signup(user.login, user.password);
            user.sid = signin(user.login, user.password).sid;

            it("should allow users to create maps", function () {
                expect(uploadMap(user.sid, "testUploadedMap", 16, ["."]).result).toBe("ok");
            });

            it("should respond with 'badSid' if user with that sid was not found", function () {
                expect(uploadMap(user.sid + "@#&*^@#$!}}", "testBadSid", 10, ["."]).result).toBe("badSid");
            });

            it("should respond with 'badName' if map name was empty", function () {
                expect(uploadMap(user.sid, "", 10, ["."]).result).toBe("badName");
            });

            it("should respond with 'badMaxPlayers' if maxPlayers field was empty", function () {
                expect(uploadMap(user.sid, "badMaxPlayersTest", "", ["."]).result).toBe("badMaxPlayers");
            });

            it("should respond with 'badMap' if row lengths are not equal", function () {
                expect(uploadMap(user.sid, "DiffLengthsTest", 16, ["...", "..", "..."]).result).toBe("badMap");
            });

        });

        describe("getMaps action", function () {

            var user = {
                login: "mapGetterLogin",
                password: "mapGetterPass"
            };

            signup(user.login, user.password);
            user.sid = signin(user.login, user.password).sid;

            var map = {
                name: "gettingMapsTest",
                maxPlayers: 4,
                map: [
                    "...",
                    "...",
                    "..."
                ]
            };
            uploadMap(user.sid, map.name, map.maxPlayers, map.map);

            it("should allow users to get map list", function () {
                var getMapsRes = getMaps(user.sid);
                expect(getMapsRes.result).toBe("ok");
                expect(getMapsRes.maps).toBeDefined();
                for (var i = 0; i < getMapsRes.maps.length; i++) {
                    if (getMapsRes.maps[i].name == map.name) {
                        var curMap = getMapsRes.maps[i];
                        console.log(curMap);
                        expect(curMap.map).toEqual(map.map);
                        expect(curMap.maxPlayers).toBe(map.maxPlayers);
                    };
                };
            });

            it("should respond with 'badSid' if user with that sid was not found", function () {
                expect(getMaps(user.sid + "$#%%").result).toBe("badSid");
            });
        });
    });

    describe("Game controlling", function () {

        var hostUser = {
            login: "host_user",
            password: "host_pass"
        };

        var joiningUser = {
            login: "joiner_login",
            password: "joiner_pass"
        };
        signup(hostUser.login, hostUser.password);
        signup(joiningUser.login, joiningUser.password);

        hostUser.sid = signin(hostUser.login, hostUser.password).sid;
        joiningUser.sid = signin(joiningUser.login, joiningUser.password).sid;

        uploadMap(hostUser.sid, "testMap", 4, ["..", ".."]);
        uploadMap(hostUser.sid, "testMap2", 4, ["."]);

        var maps = getMaps(hostUser.sid).maps;

        afterEach(function () {
            leaveGame(hostUser.sid);
            leaveGame(joiningUser.sid);
        });

        var map = maps[0];
        var map2 = maps[1];

        describe("createGame action", function () {

            it("should allow users to create games", function () {
                expect(createGame(
                    hostUser.sid, map.name + "Game", map.id, map.maxPlayers).result).toBe("ok");
            });

            it("should respond with 'gameExists' if game with requested name already exists", function () {
                var gameName = "gameNumber1";
                expect(createGame(
                    hostUser.sid, gameName, map.id, map.maxPlayers).result).toBe("ok");
                expect(createGame(
                    joiningUser.sid, gameName, map2.id, map2.maxPlayers).result).toBe("gameExists");
            });

            it("should respond with 'badName' if game name was empty", function () {
                expect(createGame(
                    hostUser.sid, "", map.id, map.maxPlayers).result).toBe("badName");
            });

            it("should respond with 'badMap' if map with that id was not found", function () {
                expect(createGame(
                    hostUser.sid, "badMapGame", map.id + "@#$@#$", map.maxPlayers).result).toBe("badMap");
            });

            it("should respond with 'badMap' if requested map id was empty", function () {
                expect(createGame(
                    hostUser.sid, "emptyMapNameGame", "", map.maxPlayers).result).toBe("badMap");
            });

            it("should respond with 'badMaxPlayers' if maxPlayers field was empty", function () {
                expect(createGame(
                    hostUser.sid, "badMaxPlayersGame", map.id, "").result).toBe("badMaxPlayers");
            });

            it("should respond with 'badMaxPlayers' if maxPlayers field was not like correct number", function () {
                expect(createGame(
                    hostUser.sid, "badMaxPlayersNaNGame", map.id, "suddenly!").result).toBe("badMaxPlayers");
            });

            it("should respond with 'alreadyInGame' if host user was trying to create two games simultaneously",
                function () {

                expect(createGame(
                    hostUser.sid, "AlreadyInGameGame1", map.id, map.maxPlayers).result).toBe("ok");
                expect(createGame(
                    hostUser.sid, "AlreadyInGameGame2", map2.id, map.maxPlayers).result).toBe("alreadyInGame");
            });

        });
    });
});

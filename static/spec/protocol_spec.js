describe("Protocol supporting server", function () {

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

    describe("Game controlling", function () {

        var hostUser = {
            login: "host_user",
            password: "host_pass"
        };

        var joiningUser = {
            login: "joiner_login",
            password: "joiner_pass"
        };

        var testMap = {
            name: "testMap",
            maxPlayers: 4,
            map: ["..", ".."]
        };
        uploadMap(testMap.name, testMap.maxPlayers, testMap.map);

        signup(hostUser.login, hostUser.password);
        signup(joiningUser.login, joiningUser.password);

        beforeEach(function () {
            hostUser.sid = signin(hostUser.login, hostUser.password);
            joiningUser.sid = signin(joiningUser.login, joiningUser.password);
        });

        describe("uploadMap action", function () {
            it("should allow users to create maps", function () {
                expect(uploadMap("testUploadedMap", ["."]).result).toBe("ok");
            });
        });
    });
});

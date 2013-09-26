describe("Protocol supporting server", function () {

    it("should response with 'unknownAction' result if it could not recognize action", function () {
        expect(getResponse({action: "asdkhasdasd"}).result).toBe("unknownAction");
    });

    describe("Signup action", function () {
        it("should require login and password", function () {
            expect(signup("signup_test_login", "signup_test_password").result).toBe("ok");
        });

        it("should provide 'userExists' result if this user already exists", function () {
            expect(signup("existing_user", "existing_password").result).toBe("ok");
            expect(signup("existing_user", "existing_password").result).toBe("userExists");
            expect(signup("existing_user", "sdkfjhsdfkjhsdf").result).toBe("userExists");
        });

        it("should provide 'badLogin' result if login is shorter than 4 symbols", function () {
            expect(signup("1", "short_test_password").result).toBe("badLogin");
        });

        it("should provide 'badLogin' result if login is longer than 40 symbols", function () {
            expect(signup("abcdefghijklmnopqrstuvwxyzabcdefghijklmnopqrstuvwxyz", "long_test_password").result)
                .toBe("badLogin");
        });

        it("should provide 'badPassword' result if password is shorter than 4 symbols", function () {
            expect(signup("short_pass_login", "1").result).toBe("badPassword");
        });
    });

    describe("Signin action", function () {

        it("should provide response with the sid after correct signin request", function () {
            var userLogin = "signin_test_login";
            var userPass = "signin_test_pass";
            expect(signup(userLogin, userPass).result).toBe("ok");
            var got = signin(userLogin, userPass);

            expect(got.result).toBe("ok");
            expect(got.sid).toBeDefined();
            expect(got.sid.length).toBeGreaterThan(0);
            expect(got.sid).toMatch(/^[a-zA-z0-9]*$/);
        });

        it("should provide 'incorrect' result if user with requested login doesn't exists", function () {
            var userLogin = "signin_incorrect_l_test_login";
            var userPass = "signin_incorrect_l_test_pass";

            expect(signup(userLogin, userPass).result).toBe("ok");
            expect(signin(userLogin + "no", userPass).result).toBe("incorrect");
            expect(signin(userLogin, userPass + "no").result).toBe("incorrect");
        });

        it("should provide 'incorrect' result if login and password don't match", function () {
            var userLogin = "signin_incorrect_p_test_login";
            var userPass = "signin_incorrect_p_test_pass";

            expect(signup(userLogin, userPass).result).toBe("ok");
            expect(signin(userLogin, userPass + "no").result).toBe("incorrect");
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

        it("should provide 'badSid' result if sid is empty" , function () {
            expect(signout("").result).toBe("badSid");
        });

        it("should provide 'badSid' result if sid could not be found" , function () {
            expect(signout("sidNotFound123").result).toBe("badSid");
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

            it("should allow user to send text to chat using the sid", function () {
                expect(sendMessage(firstUser.sid, "", "Hello").result).toBe("ok");
            });

            it("should provide 'badSid' result if user with that sid was not found", function () {
                expect(sendMessage("^&%DF&TSDFH", "", "Hello").result).toBe("badSid");
            });
        });

        describe("getMessages action", function () {

            it("should allow user to get messages using the sid", function () {

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
        });

        it("should provide 'badSid' result if user with that sid was not found", function () {
            expect(getMessages(firstUser.sid + "#W*&^W#$", "", 0).result).toBe("badSid");
        });

        it("should provide 'badGame' result if game with that id was not found", function () {
            expect(getMessages(firstUser.sid, "#$(*&", 0).result).toBe("badGame");
        });
    });
});

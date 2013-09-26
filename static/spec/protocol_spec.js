describe("Protocol supporting server", function () {

    var req;
    var res;

    function getResponse (requestData) {
        var responseData = null;

        $.ajax({
            type: "POST",
            url: "http://localhost:5000",
            dataType: "json",
            contentType: "application/json",
            async: false,
            data: JSON.stringify(requestData),
            success: function (data) {
                responseData = data;
            },
            error: function () {
                expect(true).toBe(false);
            }
        });

        return responseData;
    }

    beforeEach(function () {
        req = {
            action: "",
            params: {}
        };
        res = {};
    });

    it("should response with 'unknownAction' result if it could not recognize action", function () {
        req.action = "asdkhasdasd";
        res = getResponse(req);
        expect(res.result).toBe("unknownAction");
    });

    describe("Signup action", function () {

        beforeEach(function () {
            req.action = "signup";
        });

        it("should require login and password", function () {
            req.params = {
                login: "signup_test_login",
                password: "signup_test_password"
            };
            res = getResponse(req);
            expect(res.result).toBe("ok");
        });

        it("should provide 'userExists' result if this user already exists", function () {
            req.params = {
                login: "existing_user",
                password: "lkjasdflkjdf"
            };
            expect(getResponse(req).result).toBe("ok");
            expect(getResponse(req).result).toBe("userExists");
            req.params.password = "123ad";
            expect(getResponse(req).result).toBe("userExists");
        });

        it("should provide 'badLogin' result if login is shorter than 4 symbols", function () {
            req.params = {
                login: "1",
                password: "short_test_password"
            };
            res = getResponse(req);
            expect(res.result).toBe("badLogin");
        });

        it("should provide 'badLogin' result if login is longer than 40 symbols", function () {
            req.params = {
                login: "abcdefghijklmnopqrstuvwxyzabcdefghijklmnopqrstuvwxyz",
                password: "long_test_password"
            };
            expect(getResponse(req).result).toBe("badLogin");
        });

        it("should provide 'badPassword' result if password is shorter than 4 symbols", function () {
            req.params = {
                login: "short_pass_login",
                password: "1"
            };
            expect(getResponse());
        });

    });

    describe("Signin action", function () {

        beforeEach(function () {
            req.action = "signin";
        });

        it("should provide response with the sid after signin in", function () {
            var preReqLogin = "signin_test_login";
            var preReqPass = "signin_test_pass";
            var preReq = {
                action: "signup",
                params: {
                    login: preReqLogin,
                    password: preReqPass
                }
            };

            expect(getResponse(preReq).result).toBe("ok");
            req.params = {
                login: preReqLogin,
                password: preReqPass
            };
            res = getResponse(req);
            expect(res.result).toBe("ok");
            expect(res.sid).toBeDefined();
            expect(res.sid.length).toBeGreaterThan(0);
            expect(res.sid).toMatch(/^[a-zA-z0-9]*$/);
        });

        it("should provide 'incorrect' result if user with requested login doesn't exists", function () {
            var preReqLogin = "signin_incorrect_l_test_login";
            var preReqPass = "signin_incorrect_l_test_pass";
            var preReq = {
                action: "signup",
                params: {
                    login: preReqLogin,
                    password: preReqPass
                }
            };

            expect(getResponse(preReq).result).toBe("ok");
            req.params = {
                login: preReqLogin + "no",
                password: preReqPass
            };
            res = getResponse(req);
            expect(res.result).toBe("incorrect");
        });

        it("should provide 'incorrect' result if login and password don't match", function () {
            var preReqLogin = "signin_incorrect_p_test_login";
            var preReqPass = "signin_incorrect_p_test_pass";
            var preReq = {
                action: "signup",
                params: {
                    login: preReqLogin,
                    password: preReqPass
                }
            };

            expect(getResponse(preReq).result).toBe("ok");
            req.params = {
                login: preReqLogin,
                password: preReqPass + "no"
            };
            res = getResponse(req);
            expect(res.result).toBe("incorrect");
        });

    });

    describe("Signout action", function () {

        beforeEach(function () {
            req.action = "signout";
        });

        it("should allow user to sign out using the sid", function () {
            var userLogin = "signout_test_login";
            var userPassword = "singout_test_pass";
            var signupRequest = {
                action: "signup",
                params: {
                    login: userLogin,
                    password: userPassword
                }
            }
            expect(getResponse(signupRequest).result).toBe("ok");

            var signinRequest = {
                action: "signin",
                params: {
                    login: userLogin,
                    password: userPassword
                }
            }
            var signinResponse = getResponse(signinRequest);
            expect(signinResponse.result).toBe("ok");
            expect(signinResponse.sid).toBeDefined();

            req.params = {
                sid: signinResponse.sid
            };

            expect(getResponse(req).result).toBe("ok");
        });

        it("should provide 'badSid' result if sid is empty" , function () {
            req.params.sid = "";
            expect(getResponse(req).result).toBe("badSid");
        });

        it("should provide 'badSid' result if sid could not be found" , function () {
            req.params.sid = "sidNotFound123";
            expect(getResponse(req).result).toBe("badSid");
        });
    });

    describe("sendMessage action", function () {

        beforeEach(function () {
            req.action = "sendMessage";
        });

        it("should allow user to send text to chat using the sid", function () {
            var userLogin = "send_message_login";
            var userPassword = "send_message_pass";
            var signupRequest = {
                action: "signup",
                params: {
                    login: userLogin,
                    password: userPassword
                }
            };
            expect(getResponse(signupRequest).result).toBe("ok");
            var signinRequest = {
                action: "signin",
                params: {
                    login: userLogin,
                    password: userPassword
                }
            };
            var signinResponse = getResponse(signinRequest);
            expect(signinResponse.result).toBe("ok");
            var userSid = signinResponse.sid;

            req.params = {
                sid: userSid,
                game: "",
                text: "Hello"
            };
            expect(getResponse(req).result).toBe("ok");
        });

        it("should provide 'badSid' result if user with that sid was not found", function () {
            req.params = {
                sid: "^&%DF&TSDFH",
                game: "",
                text: "Hello"
            };
        });
    });

    describe("getMessages action", function () {

        beforeEach(function () {
            req.action = "getMessages";
        });

        it("should allow user to get messages using the sid", function () {
           var userLogin = "get_messages_login";
           var userPassword = "get_messages_pass";
           var signupRequest = {
               action: "signup",
               params: {
                   login: userLogin,
                   password: userPassword
               }
           };
           expect(getResponse(signupRequest).result).toBe("ok");
           var signinRequest = {
               action: "signin",
               params: {
                   login: userLogin,
                   password: userPassword
               }
           };
           var signinResponse = getResponse(signinRequest);
           expect(signinResponse.result).toBe("ok");
           var userSid = signinResponse.sid;

           var messagesCount = 3;
           for (var i = 0; i < messagesCount; i++) {
                var curReq = {
                    action: "sendMessage",
                    params: {
                        sid: userSid,
                        game: "",
                        text: i + "hi"
                    }
                };
           };

           req.params = {
               sid: userSid,
               game: "",
               since: 0
           };

           res = getResponse(req);
           expect(res.result).toBe("ok");
           for (var i = res.messages.length - 1; i >= res.messages.length - messagesCount; i--) {
               expect(res.messages[i].time).toBeGreaterThan(res.messages[i - 1].time);
           };
        });
    });


});

var tests = [

    {
        name: "Unknown action",
        input: {
            action: "aw##$#$!@",
            params: {}
        }
        expected: {
            result: "unknownAction"
        }
    },

    {
        name: "Correct signup",
        input: {
            action: "signup",
            params: {
                login: "test-login",
                password: "test-password"
            }
        },
        expected: {
            result: "ok"
    },

    {
        name: "Incorrect signup (empty login)",
        input: {
            action: "signup",
            params: {
                login: "",
                password: "test-password"
            }
        },
        expected: {
            result: "badLogin"
        }
    },

    {
        name: "Incorrect signup (login too long)",
        input: {
            action: "signup",
            params: {
                login: "123456789012345678901234567890123456789012345",
                password: ""
            }
        },
        expected: {
            result: "badLogin"
        }
    },

    {
        name: "Incorrect signup (empty password)",
        input: {
            action: "signup",
            params: {
                login: "lkjhasdkjhasdfkjh",
                password: ""
            }
        },
        expected: {
            result: "badPassword"
        }
    },

    {
        name: "Incorrect signup (user exists)",
        input: {
            action: "signup",
            params: {
                login: "test-login",
                password: "test-password"
            }
        },
        expected: {
            result: "badLogin"
        }
    }
]

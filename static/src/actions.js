var getResponse = function (action, params = {}) {
    var responseData = null;

    $.ajax({
        type: "POST",
        url: "http://localhost:5000",
        dataType: "json",
        contentType: "application/json",
        async: false,
        data: JSON.stringify({action: action, params: params}),
        success: function (data) {
            responseData = data;
        },
        error: function () {
            expect(true).toBe(false);
        }
    });

    return responseData;
};

var startTesting = function () {
    return getResponse("startTesting");
};

var signup = function (login, password) {
    return getResponse("signup", {
        login: login,
        password: password
    });
};

var signin = function (login, password) {
    return getResponse("signin", {
        login: login,
        password: password
    });
}

var signout = function (sid) {
    return getResponse("signout", {
        sid: sid
    });
};

var sendMessage = function (sid, game, text) {
    return getResponse("sendMessage", {
        sid: sid,
        game: game,
        text: text
    });
};

var getMessages = function (sid, game, since) {
    return getResponse("getMessages", {
        sid: sid,
        game: game,
        since: since
    });
};

var createGame = function (sid, name, map, maxPlayers) {
    return getResponse("createGame", {
        sid: sid,
        name: name,
        map: map,
        maxPlayers: maxPlayers
    });
}

var getGames = function (sid) {
    return getResponse("getGames", {
        sid: sid
    });
};

var joinGame = function (sid, game) {
    return getResponse("joinGame", {
        sid: sid,
        game: game
    });
};

var leaveGame = function (sid) {
    return getResponse("leaveGame", {
        sid: sid
    });
};

var uploadMap = function (name, maxPlayers, map = []) {
    return getResponse("uploadMap", {
        name: name,
        maxPlayers: maxPlayers,
        map: map
    });
};

var getMaps = function(sid) {
    return getResponse("getMaps", {
        sid: sid
    });
}

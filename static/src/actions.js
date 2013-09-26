var getResponse = function (action, pararms) {
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

var signup = function (login, password) {
    params = {
        login: login,
        password: password
    };
    return getResponse("signup", params);
};

var signin = function (login, password) {
    params = {
        login: login,
        password: password
    };
    return getResponse("signin", params);
}

var signout = function (sid) {
    params = {
        sid: sid
    };
    return getResponse("signout", params);
};

var sendMessage = function (sid, game, text) {
    params = {
        sid: sid,
        game: game,
        text: text
    };
    return getResponse("sendMessage", params);
};

var getMessages = function (sid, game, since) {
    params = {
        sid: sid,
        game: game,
        since: since
    };
    return getResponse("getMessages", params);
};

var createGame = function (sid, name, map, maxPlayers) {
    params = {
        sid: sid,
        name: name,
        map: map,
        maxPlayers: maxPlayers
    };
    return getResponse("createGame", params);
}

var getGames(sid) {
    params = {
        sid: sid
    };
    return getResponse("getGames", params);
};

var joinGame(sid, game) {
    params = {
        sid: sid,
        game: game
    };
    return getResponse("joinGame", params);
};

var leaveGame(sid) {
    params = {
        sid: sid
    };
    return getResponse("leaveGame", params);
};

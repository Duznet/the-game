function runTests () {
    for (var i = 0; i < tests.length; i++) {
        var test = tests[i];
        test.id = i;
        $.ajax({
            type: "POST",
            url: "http://localhost:5000",
            data: JSON.stringify(test.input),
            dataType: "json",
            contentType: "application/json",
            success: function (data) {
                test.got = JSON.parse(data);
                check(test);
            },
            error: function () {
                writeResult("failed", test, "Could not get the response!");
            }
        });
    };
};

function check(test) {
    var result = "";
    for (var property in expected) {
        if (got[property] !== expected[property]) {
            result = "failed";
            break;
        }
        result = "ok";
    };
    writeResult(result, test);
}

function writeResult(result, test, message = "") {
    $('<div>').addClass(result)
        .html("#" + test.id + " " + test.name + ": " + result + " " + message)
        .appendTo($('#results'));
}

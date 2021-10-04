var ExtensionClass = function() { };

ExtensionClass.prototype = {
    run: function(arguments) {
        arguments.completionFunction({
            "url": window.location.href,
            "html": document.documentElement.innerHTML
        });
    }
};

var ExtensionPreprocessingJS = new ExtensionClass;

int main(string[] args) {
    Wnck.Screen.get_default();
    var app = new NovaDock.Application();
    return app.run(args);
}

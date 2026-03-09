/* entry point: initialise wnck and start the application */
int main(string[] args) {
    Wnck.set_client_type(Wnck.ClientType.PAGER);
    var app = new NovaDock.Application();
    return app.run(args);
}

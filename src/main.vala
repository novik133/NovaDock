int main(string[] args) {
    stderr.printf("NovaDock starting...\n");
    var app = new NovaDock.Application();
    stderr.printf("Application created, running...\n");
    int ret = app.run(args);
    stderr.printf("Application exited with code %d\n", ret);
    return ret;
}

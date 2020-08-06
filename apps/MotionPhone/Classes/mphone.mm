/* mphone.C
 * Author: Scott S. Snibbe
 */

#include "ui.H"
#include "net.H"

#include <sys/wait.h>
#include <sys/prctl.h>

extern mphone_serve(void);

static UI *ui;
static Net *net;

static void
cleanup() 
{
    printf("Motion Phone Exiting\nGoodbye!\n");

    delete ui;
    exit(0);
}

static void
start_server(void *)
{
    net->serve();
}

void
main (int argc, char **argv)
{
    pid_t       child_pid;
    int         host[MAX_HOSTS];

    net = new Net();

    ui = new UI(argc, argv, net);

    net->set_mcanvas(ui->mcanvas, &ui->from_net);

    // tell sendmessage what our mcanvas is...
    sendmessage_set_friends(ui->mcanvas, net);

    printf("sizeof(Net_Message) = %d\n", sizeof(Net_Message));

    child_pid = sproc(start_server, PR_SADDR);

    printf("child_process = %d, this_process: %d\n", child_pid, getpid());

    for (int i = 1; i < argc; i++)
        host[i-1] = net->add_host(argv[i]);
    
    

    net->init_all_clients();

    printf("Starting UI\n");

    ui->start();

    net->kill_all_clients();

    printf("Killing shared server process\n");
    kill(child_pid, SIGKILL);

    printf("End of the world\n");
}

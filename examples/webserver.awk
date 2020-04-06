@load "filefuncs"
@load "readfile"
BEGIN {
    RS = ORS = "\r\n"
    datefmt = "Date: %a, %d %b %Y %H:%M:%S %Z"
    socket = "/inet/tcp/8080/0/0"
    while ((socket |& getline) > 0) {
        if ( $1 == "GET" ) { 
            print "GET : ", $2 
            $2 = substr($2,2)
            switch ($2) {
                case /\.(jpg|gif|png)$/ :
                    sendImage($2)
                    break
                default :
                    sendHtml()
            }
        }
    }
}
function sendHtml(    a, arr) {
    arr["type"] = "text/html"
    arr["content"] = "\
     <HTML>\n\
     <HEAD><TITLE>Out Of Service</TITLE></HEAD>\n\
     <BODY>\n\
           <H1>This site is temporarily out of service.</H1>\n\
           <P><img src=cat.jpg></P>\n\
     </BODY>\n\
     </HTML>\n\
     "
    arr["length"] = length(arr["content"])
    arr["date"] = strftime(datefmt, systime(), 1)

    send(arr)
}
function sendImage(file,     c, a, arr, type) {
    RS="\n"
    c = "file -b --mime-type '" file "'"
    c | getline type; close(c)
    RS="\r\n"
    arr["type"] = type
    stat(file, a)
    arr["length"] = a["size"]
    arr["content"] = readfile(file)
    arr["date"] = strftime(datefmt, systime(), 1)
    
    send(arr)
}
function send(arr) {
    print "HTTP/1.0 200 OK"                    |& socket
    print arr["date"]                          |& socket
    print "Server: AWK"                        |& socket
    print "Content-Length: " arr["length"]     |& socket
    print "Content-Type: " arr["type"]         |& socket
    print ""                                   |& socket
    print arr["content"]                       |& socket
    
    print "close socket"
    close(socket)
}

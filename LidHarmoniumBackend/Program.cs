

using System.Net.Sockets;
using System.Net.WebSockets;
using System.Text;

var builder = WebApplication.CreateBuilder(args);

var app = builder.Build();


app.UseWebSockets();

app.Map("ws/sensor", async context =>
{
    if (context.WebSockets.IsWebSocketRequest)
    {
        //get the connection
        using var webSocket = await context.WebSockets.AcceptWebSocketAsync();
        Console.WriteLine("Conncted");

        await ProcessSensorData(webSocket);

    }else
    {
        context.Response.StatusCode = 400;
    }
});

app.MapGet("/", () => "ALl set Boss");
app.Run();


async Task ProcessSensorData(WebSocket webSocket)
{
    var buffer = new byte[1024 * 4];

    while(webSocket.State == WebSocketState.Open)
    {
        var result = await webSocket.ReceiveAsync(new ArraySegment<byte>(buffer), CancellationToken.None);


        if(result.MessageType == WebSocketMessageType.Text)
        {
            var jsonString = Encoding.UTF8.GetString(buffer, 0, result.Count);
            Console.WriteLine($"Live : {jsonString}");
        }
        else if(result.MessageType == WebSocketMessageType.Close)
        {
            Console.WriteLine("Closed.");
            await webSocket.CloseAsync(WebSocketCloseStatus.NormalClosure, "Closed by server", CancellationToken.None);
        }
    }
}


using System.Net.WebSockets;
using System.Text;
using System.Text.Json;

var builder = WebApplication.CreateBuilder(args);
var app = builder.Build();

app.UseWebSockets();


double CurrentVolume = 0.5;
double CurrentFrequency = 0.0; 

app.Map("/ws/sensor", async context =>
{
    if (context.WebSockets.IsWebSocketRequest)
    {
        using var webSocket = await context.WebSockets.AcceptWebSocketAsync();
        Console.WriteLine("Harmonium Connected");
        await ProcessHarmonium(webSocket);
    }
    else
    {
        context.Response.StatusCode = 400;
    }
});

app.Run();

async Task ProcessHarmonium(WebSocket socket)
{
    var buffer = new byte[1024 * 4];

    while (socket.State == WebSocketState.Open)
    {
        var result = await socket.ReceiveAsync(new ArraySegment<byte>(buffer), CancellationToken.None);

        if (result.MessageType == WebSocketMessageType.Text)
        {
            try 
            {
                var jsonString = Encoding.UTF8.GetString(buffer, 0, result.Count);
                using var doc = JsonDocument.Parse(jsonString);
                var root = doc.RootElement;


                if (root.TryGetProperty("angle", out var angleProp))
                {
                    double angle = angleProp.GetDouble();
                    CurrentVolume = Math.Clamp(angle / 90.0, 0.0, 1.0);
                }

                if (root.TryGetProperty("key", out var keyProp))
                {
                    string key = keyProp.GetString() ?? "";
                    bool isDown = false;
                    if(root.TryGetProperty("isDown", out var downProp)) isDown = downProp.GetBoolean();
                    
                    if (isDown)
                    {
                        CurrentFrequency = MapKeyToFreq(key);
                    }
                    else
                    {
                        CurrentFrequency = 0.0;
                    }
                }

                var response = new { freaquency = CurrentFrequency, volume = CurrentVolume };
                var responseBytes = Encoding.UTF8.GetBytes(JsonSerializer.Serialize(response));
                
                await socket.SendAsync(
                    new ArraySegment<byte>(responseBytes),
                    WebSocketMessageType.Text,
                    true,
                    CancellationToken.None);

            }
            catch (Exception ex) 
            {
                
            }
        }
        else if (result.MessageType == WebSocketMessageType.Close)
        {
            await socket.CloseAsync(WebSocketCloseStatus.NormalClosure, "Bye", CancellationToken.None);
        }
    }
}

double MapKeyToFreq(string key)
{
    return key.ToLower() switch
    {
        "a" => 261.63, // C4
        "s" => 293.66, // D4
        "d" => 329.63, // E4
        "f" => 349.23, // F4
        "g" => 392.00, // G4
        "h" => 440.00, // A4
        "j" => 493.88, // B4
        "k" => 523.25, // C5
        "l" => 587.33, // D5
        _ => 0.0
    };
}
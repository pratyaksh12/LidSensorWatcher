
using System.Net.WebSockets;
using System.Text;
using System.Text.Json;

var builder = WebApplication.CreateBuilder(args);
var app = builder.Build();

app.UseWebSockets();


double CurrentVolume = 0.0;
double CurrentFrequency = 0.0; 


double AirPressure = 0.0; 
double LastAngle = -1.0; 


SemaphoreSlim _socketLock = new SemaphoreSlim(1, 1);

app.Map("/ws/sensor", async context =>
{
    if (context.WebSockets.IsWebSocketRequest)
    {
        using var webSocket = await context.WebSockets.AcceptWebSocketAsync();
        Console.WriteLine("Harmonium Connected (Push Mode)");
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
    var cts = new CancellationTokenSource();

    var broadcastTask = Task.Run(async () => 
    {
        while (!cts.Token.IsCancellationRequested && socket.State == WebSocketState.Open)
        {
            await Task.Delay(16);
            if (AirPressure > 0.001)
            {
                AirPressure *= 0.98; 
            }
            else
            {
                AirPressure = 0.0;
            }

            CurrentVolume = (CurrentVolume * 0.90) + (AirPressure * 0.10);
            

            CurrentVolume = Math.Clamp(CurrentVolume, 0.0, 1.0);


            await SendState(socket);
        }
    }, cts.Token);


    var buffer = new byte[1024 * 4];
    try 
    {
        while (socket.State == WebSocketState.Open)
        {
            var result = await socket.ReceiveAsync(new ArraySegment<byte>(buffer), CancellationToken.None);

            if (result.MessageType == WebSocketMessageType.Text)
            {
                var jsonString = Encoding.UTF8.GetString(buffer, 0, result.Count);
                ProcessInput(jsonString);
                

                await SendState(socket); 
            }
            else if (result.MessageType == WebSocketMessageType.Close)
            {
                cts.Cancel(); 
                await socket.CloseAsync(WebSocketCloseStatus.NormalClosure, "Bye", CancellationToken.None);
            }
        }
    }
    catch
    {
        cts.Cancel();
    }
    
    await broadcastTask;
}

void ProcessInput(string jsonString)
{
    try 
    {
        using var doc = JsonDocument.Parse(jsonString);
        var root = doc.RootElement;

        if (root.TryGetProperty("angle", out var angleProp))
        {
            double currentAngle = angleProp.GetDouble();
            
            if (LastAngle >= 0)
            {
                double delta = Math.Abs(currentAngle - LastAngle);

                double pumpAmount = delta * 0.05; 
                AirPressure += pumpAmount;
                AirPressure = Math.Clamp(AirPressure, 0.0, 1.0);
            }
            LastAngle = currentAngle;
        }


        if (root.TryGetProperty("key", out var keyProp))
        {
            string key = keyProp.GetString() ?? "";
            bool isDown = false;
            if(root.TryGetProperty("isDown", out var downProp)) isDown = downProp.GetBoolean();
            
            CurrentFrequency = isDown ? MapKeyToFreq(key) : 0.0;
        }
    }
    catch {}
}

async Task SendState(WebSocket socket)
{

    await _socketLock.WaitAsync();
    try
    {
        if(socket.State == WebSocketState.Open)
        {
            var response = new { freaquency = CurrentFrequency, volume = CurrentVolume };
            var responseBytes = Encoding.UTF8.GetBytes(JsonSerializer.Serialize(response));
            
            await socket.SendAsync(
                new ArraySegment<byte>(responseBytes),
                WebSocketMessageType.Text,
                true,
                CancellationToken.None);
        }
    }
    finally
    {
        _socketLock.Release();
    }
}

double MapKeyToFreq(string key)
{
    return key.ToLower() switch
    {
        "a" => 261.63, "s" => 293.66, "d" => 329.63, "f" => 349.23,
        "g" => 392.00, "h" => 440.00, "j" => 493.88, "k" => 523.25, "l" => 587.33,
        _ => 0.0
    };
}
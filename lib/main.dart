import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:weather_icons/weather_icons.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'SkyVision | Previsão do Tempo',
      home: WeatherApp(),
    );
  }
}

class WeatherApp extends StatefulWidget {
  @override
  _WeatherAppState createState() => _WeatherAppState();
}

class _WeatherAppState extends State<WeatherApp> {
  TextEditingController _cityController = TextEditingController();
  String _currentWeatherData = '';
  IconData _currentWeatherIcon =
      WeatherIcons.day_sunny; // Ícone padrão para clima ensolarado
  List<HourlyForecast> _hourlyForecasts = []; // Lista de previsões horárias
  final _apiKey =
      '0668d82a2696a4e03f3966460b176bdb'; // Substitua pela sua própria chave da API de previsão do tempo

  Future<void> _getWeatherData(String city) async {
    final apiKey = _apiKey;
    final apiUrl =
        'https://api.openweathermap.org/data/2.5/weather?q=$city&appid=$apiKey';
    final hourlyApiUrl =
        'https://api.openweathermap.org/data/2.5/forecast?q=$city&appid=$apiKey';

    try {
      final response = await http.get(Uri.parse(apiUrl));

      if (response.statusCode == 200) {
        Map<String, dynamic> weatherJson = json.decode(response.body);
        double temperature = weatherJson['main']['temp'].toDouble() -
            273.15; // Convertendo de Kelvin para Celsius

        // Definindo o ícone com base na condição climática
        int weatherId = weatherJson['weather'][0]['id'];
        _currentWeatherIcon = _getWeatherIcon(weatherId);

        setState(() {
          _currentWeatherData =
              'Temperatura Atual: ${temperature.toStringAsFixed(1)}°C\n'
              'Condição: ${_getWeatherConditionInPortuguese(weatherJson['weather'][0]['description'])}';
        });
      } else {
        setState(() {
          _currentWeatherData =
              'Erro ao obter dados. Certifique-se de digitar uma cidade válida.';
        });
      }

      // Obtendo previsões horárias
      final hourlyResponse = await http.get(Uri.parse(hourlyApiUrl));

      if (hourlyResponse.statusCode == 200) {
        List<dynamic> hourlyJson = json.decode(hourlyResponse.body)['list'];
        _hourlyForecasts = hourlyJson
            .map((hourly) => HourlyForecast(
                  time:
                      DateTime.fromMillisecondsSinceEpoch(hourly['dt'] * 1000),
                  temperature: hourly['main']['temp'].toDouble() - 273.15,
                  weatherIcon: _getWeatherIcon(hourly['weather'][0]['id']),
                ))
            .toList();
      } else {
        // Lidar com erro ao obter previsões horárias
      }
    } catch (e) {
      setState(() {
        _currentWeatherData =
            'Erro ao obter dados. Verifique sua conexão com a internet.';
      });
    }
  }

  IconData _getWeatherIcon(int weatherId) {
    if (weatherId >= 200 && weatherId < 300) {
      return WeatherIcons.day_thunderstorm;
    } else if (weatherId >= 300 && weatherId < 600) {
      return WeatherIcons.day_rain;
    } else if (weatherId >= 600 && weatherId < 700) {
      return WeatherIcons.day_snow;
    } else if (weatherId >= 700 && weatherId < 800) {
      return WeatherIcons.day_fog;
    } else if (weatherId == 800) {
      return WeatherIcons.day_sunny;
    } else if (weatherId == 801 || weatherId == 802) {
      return WeatherIcons.day_cloudy;
    } else if (weatherId == 803 || weatherId == 804) {
      return WeatherIcons.day_cloudy_high;
    } else {
      return WeatherIcons
          .day_sunny_overcast; // Ícone padrão para outras condições
    }
  }

  String _getWeatherConditionInPortuguese(String condition) {
    Map<String, String> translations = {
      'clear sky': 'céu limpo',
      'few clouds': 'poucas nuvens',
      'scattered clouds': 'nuvens dispersas',
      'broken clouds': 'nuvens quebradas',
      'shower rain': 'chuva isolada',
      'rain': 'chuva',
      'thunderstorm': 'tempestade',
      'snow': 'neve',
      'mist': 'neblina',
    };

    return translations[condition.toLowerCase()] ?? condition;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('SkyVision'),
        backgroundColor: Colors.orange,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            TextField(
              controller: _cityController,
              decoration: InputDecoration(
                labelText: 'Digite o nome da cidade',
              ),
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                if (_cityController.text.isNotEmpty) {
                  _getWeatherData(_cityController.text);
                }
              },
              child: Text('Buscar'),
              style: ElevatedButton.styleFrom(
                primary: Colors.blue,
              ),
            ),
            SizedBox(height: 16),
            Icon(
              _currentWeatherIcon,
              size: 50,
              color: Colors.grey,
            ),
            SizedBox(height: 8),
            Text(
              _currentWeatherData,
              style: TextStyle(fontSize: 18),
            ),
            SizedBox(height: 16),
            Text(
              'Próximas 5 horas:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Expanded(
              child: ListView.builder(
                itemCount: _hourlyForecasts.length,
                itemBuilder: (context, index) {
                  final forecast = _hourlyForecasts[index];
                  return ListTile(
                    title: Text(
                      '${forecast.time.hour}:${forecast.time.minute} - ${forecast.temperature.toStringAsFixed(1)}°C',
                    ),
                    leading: Icon(forecast.weatherIcon, color: Colors.grey),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class HourlyForecast {
  final DateTime time;
  final double temperature;
  final IconData weatherIcon;

  HourlyForecast({
    required this.time,
    required this.temperature,
    required this.weatherIcon,
  });
}

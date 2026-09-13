import 'package:flutter/material.dart';

class CategoryIcon {
  const CategoryIcon(this.key, this.icon, this.label);

  final String key;
  final IconData icon;
  final String label;
}

const List<CategoryIcon> groupIcons = [
  CategoryIcon('groups', Icons.groups, 'Generic'),
  CategoryIcon('travel_explore', Icons.travel_explore, 'Trip'),
  CategoryIcon('home', Icons.home, 'Home'),
  CategoryIcon('apartment', Icons.apartment, 'Apartment'),
  CategoryIcon('cottage', Icons.cottage, 'Cottage'),
  CategoryIcon('cabin', Icons.cabin, 'Cabin'),
  CategoryIcon('villa', Icons.villa, 'Villa'),
  CategoryIcon('flight', Icons.flight, 'Flight'),
  CategoryIcon('hotel', Icons.hotel, 'Hotel'),
  CategoryIcon('restaurant_menu', Icons.restaurant_menu, 'Food'),
  CategoryIcon('local_cafe', Icons.local_cafe, 'Cafe'),
  CategoryIcon('local_bar', Icons.local_bar, 'Bar'),
  CategoryIcon('outdoor_grill', Icons.outdoor_grill, 'BBQ'),
  CategoryIcon('beach_access', Icons.beach_access, 'Beach'),
  CategoryIcon('hiking', Icons.hiking, 'Hiking'),
  CategoryIcon('forest', Icons.forest, 'Nature'),
  CategoryIcon('park', Icons.park, 'Park'),
  CategoryIcon('landscape', Icons.landscape, 'Landscape'),
  CategoryIcon('directions_car', Icons.directions_car, 'Road trip'),
  CategoryIcon('directions_bus', Icons.directions_bus, 'Bus'),
  CategoryIcon('directions_bike', Icons.directions_bike, 'Cycle'),
  CategoryIcon('directions_boat', Icons.directions_boat, 'Boat'),
  CategoryIcon('train', Icons.train, 'Train'),
  CategoryIcon('tram', Icons.tram, 'Tram'),
  CategoryIcon('two_wheeler', Icons.two_wheeler, 'Bike'),
  CategoryIcon('celebration', Icons.celebration, 'Party'),
  CategoryIcon('casino', Icons.casino, 'Casino'),
  CategoryIcon('stadium', Icons.stadium, 'Stadium'),
  CategoryIcon('golf_course', Icons.golf_course, 'Golf'),
  CategoryIcon('museum', Icons.museum, 'Museum'),
  CategoryIcon('castle', Icons.castle, 'Castle'),
  CategoryIcon('mosque', Icons.mosque, 'Mosque'),
  CategoryIcon('temple_buddhist', Icons.temple_buddhist, 'Temple'),
  CategoryIcon('fitness_center', Icons.fitness_center, 'Fitness'),
  CategoryIcon('school', Icons.school, 'Study'),
  CategoryIcon('work', Icons.work, 'Work'),
  CategoryIcon('pets', Icons.pets, 'Pets'),
  CategoryIcon('family_restroom', Icons.family_restroom, 'Family'),
  CategoryIcon('weekend', Icons.weekend, 'Weekend'),
  CategoryIcon('shopping_bag', Icons.shopping_bag, 'Shopping'),
];

const List<CategoryIcon> expenseCategoryIcons = [
  CategoryIcon('receipt_long', Icons.receipt_long, 'Other'),
  CategoryIcon('restaurant_menu', Icons.restaurant_menu, 'Dining'),
  CategoryIcon('restaurant', Icons.restaurant, 'Restaurant'),
  CategoryIcon('lunch_dining', Icons.lunch_dining, 'Lunch'),
  CategoryIcon('dinner_dining', Icons.dinner_dining, 'Dinner'),
  CategoryIcon('bakery_dining', Icons.bakery_dining, 'Bakery'),
  CategoryIcon('ramen_dining', Icons.ramen_dining, 'Noodles'),
  CategoryIcon('takeout_dining', Icons.takeout_dining, 'Takeaway'),
  CategoryIcon('local_cafe', Icons.local_cafe, 'Coffee'),
  CategoryIcon('emoji_food_beverage', Icons.emoji_food_beverage, 'Chai'),
  CategoryIcon('local_pizza', Icons.local_pizza, 'Pizza'),
  CategoryIcon('fastfood', Icons.fastfood, 'Snacks'),
  CategoryIcon('icecream', Icons.icecream, 'Ice cream'),
  CategoryIcon('cake', Icons.cake, 'Cake'),
  CategoryIcon('local_bar', Icons.local_bar, 'Bar'),
  CategoryIcon('local_drink', Icons.local_drink, 'Drinks'),
  CategoryIcon('local_grocery_store', Icons.local_grocery_store, 'Groceries'),
  CategoryIcon('storefront', Icons.storefront, 'Store'),
  CategoryIcon('local_mall', Icons.local_mall, 'Mall'),
  CategoryIcon('shopping_cart', Icons.shopping_cart, 'Cart'),
  CategoryIcon('local_taxi', Icons.local_taxi, 'Taxi'),
  CategoryIcon('directions_car', Icons.directions_car, 'Car'),
  CategoryIcon('directions_bus', Icons.directions_bus, 'Bus'),
  CategoryIcon('directions_bike', Icons.directions_bike, 'Cycle'),
  CategoryIcon('two_wheeler', Icons.two_wheeler, 'Scooter'),
  CategoryIcon('airport_shuttle', Icons.airport_shuttle, 'Cab'),
  CategoryIcon('local_gas_station', Icons.local_gas_station, 'Fuel'),
  CategoryIcon('local_car_wash', Icons.local_car_wash, 'Car wash'),
  CategoryIcon('flight', Icons.flight, 'Flight'),
  CategoryIcon('train', Icons.train, 'Train'),
  CategoryIcon('tram', Icons.tram, 'Tram'),
  CategoryIcon('hotel', Icons.hotel, 'Hotel'),
  CategoryIcon('shopping_bag', Icons.shopping_bag, 'Shopping'),
  CategoryIcon('movie', Icons.movie, 'Movies'),
  CategoryIcon('video_game', Icons.videogame_asset, 'Games'),
  CategoryIcon('sports_esports', Icons.sports_esports, 'Gaming'),
  CategoryIcon('stadium', Icons.stadium, 'Match'),
  CategoryIcon('emoji_events', Icons.emoji_events, 'Award'),
  CategoryIcon('sports', Icons.sports, 'Sports'),
  CategoryIcon('fitness_center', Icons.fitness_center, 'Gym'),
  CategoryIcon('directions_run', Icons.directions_run, 'Run'),
  CategoryIcon('music_note', Icons.music_note, 'Music'),
  CategoryIcon('palette', Icons.palette, 'Art'),
  CategoryIcon('camera_alt', Icons.camera_alt, 'Camera'),
  CategoryIcon('photo_library', Icons.photo_library, 'Photos'),
  CategoryIcon('electric_bolt', Icons.electric_bolt, 'Electricity'),
  CategoryIcon('device_thermostat', Icons.device_thermostat, 'AC'),
  CategoryIcon('water_drop', Icons.water_drop, 'Water'),
  CategoryIcon('wifi', Icons.wifi, 'Internet'),
  CategoryIcon('phone_iphone', Icons.phone_iphone, 'Mobile'),
  CategoryIcon('local_laundry_service', Icons.local_laundry_service, 'Laundry'),
  CategoryIcon('cleaning_services', Icons.cleaning_services, 'Cleaning'),
  CategoryIcon('home_repair_service', Icons.home_repair_service, 'Home repair'),
  CategoryIcon('electrical_services', Icons.electrical_services, 'Electrics'),
  CategoryIcon('handyman', Icons.handyman, 'Handyman'),
  CategoryIcon('build', Icons.build, 'Repair'),
  CategoryIcon('local_florist', Icons.local_florist, 'Flowers'),
  CategoryIcon('yard', Icons.yard, 'Garden'),
  CategoryIcon('agriculture', Icons.agriculture, 'Farm'),
  CategoryIcon('spa', Icons.spa, 'Spa'),
  CategoryIcon('medical_services', Icons.medical_services, 'Medicines'),
  CategoryIcon('local_pharmacy', Icons.local_pharmacy, 'Pharmacy'),
  CategoryIcon('monitor_heart', Icons.monitor_heart, 'Health'),
  CategoryIcon('vaccines', Icons.vaccines, 'Vaccine'),
  CategoryIcon('child_care', Icons.child_care, 'Kids'),
  CategoryIcon('toys', Icons.toys, 'Toys'),
  CategoryIcon('pets', Icons.pets, 'Pets'),
  CategoryIcon('celebration', Icons.celebration, 'Party'),
  CategoryIcon('school', Icons.school, 'Education'),
  CategoryIcon('home', Icons.home, 'Rent'),
  CategoryIcon('paid', Icons.paid, 'Cash'),
  CategoryIcon('attach_money', Icons.attach_money, 'Money'),
  CategoryIcon('account_balance', Icons.account_balance, 'Bank'),
  CategoryIcon('local_atm', Icons.local_atm, 'ATM'),
  CategoryIcon('savings', Icons.savings, 'Savings'),
  CategoryIcon('currency_exchange', Icons.currency_exchange, 'Exchange'),
  CategoryIcon('sell', Icons.sell, 'Sale'),
  CategoryIcon('redeem', Icons.redeem, 'Gift'),
];

final Map<String, IconData> _groupIconsByKey = {
  for (final item in groupIcons) item.key: item.icon,
};

final Map<String, IconData> _expenseIconsByKey = {
  for (final item in expenseCategoryIcons) item.key: item.icon,
};

IconData groupIconFromKey(String? key) {
  return _groupIconsByKey[key] ?? _groupIconsByKey['groups']!;
}

IconData expenseIconFromKey(String? key) {
  return _expenseIconsByKey[key] ?? _expenseIconsByKey['receipt_long']!;
}
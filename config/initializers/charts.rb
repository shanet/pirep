Rails.configuration.sectional_charts = {
  # Continential US
  #
  # The order here is important to ensure the proper overlap between neighboring charts.
  # They are ordered in rows right to left from top-right (Haliax) to bottom-left (Brownsville).
  halifax: {
    archive: 'Halifax.zip',
    filename: 'Halifax SEC.tif',
    bounding_box: [-69.3042811, 43.5526379, -60.6248382, 48.2187551],
  },
  montreal: {
    archive: 'Montreal.zip',
    filename: 'Montreal SEC.tif',
    bounding_box: [-77.3064648, 43.9208312, -68.3369328, 48.2156321],
  },
  lake_huron: {
    archive: 'Lake_Huron.zip',
    filename: 'Lake Huron SEC.tif',
    bounding_box: [-85.3040691, 43.9195602, -76.3358869, 48.2171498],
  },
  green_bay: {
    archive: 'Green_Bay.zip',
    filename: 'Green Bay SEC.tif',
    bounding_box: [-93.3133946, 43.9190472, -84.316315, 48.3356471],
  },
  twin_cities: {
    archive: 'Twin_Cities.zip',
    filename: 'Twin Cities SEC.tif',
    bounding_box: [-101.3382474, 44.405018, -92.2669922, 49.0245225],
  },
  billings: {
    archive: 'Billings.zip',
    filename: 'Billings SEC.tif',
    bounding_box: [-109.3369135, 44.4043173, -100.2730797, 49.0213015],
  },
  great_falls: {
    archive: 'Great_Falls.zip',
    filename: 'Great Falls SEC.tif',
    bounding_box: [-117.336362, 44.406005, -108.267849, 49.0164353],
  },
  seattle: {
    archive: 'Seattle.zip',
    filename: 'Seattle SEC.tif',
    bounding_box: [-125.3378861, 44.4049085, -116.2736886, 49.01638],
  },

  new_york: {
    archive: 'New_York.zip',
    filename: 'New York SEC.tif',
    bounding_box: [-77.2850118, 39.926167, -68.6530107, 44.2118842],
  },
  detroit: {
    archive: 'Detroit.zip',
    filename: 'Detroit SEC.tif',
    bounding_box: [-85.2823252, 39.9242674, -76.6402788, 44.1991724],
  },
  chicago: {
    archive: 'Chicago.zip',
    filename: 'Chicago SEC.tif',
    bounding_box: [-93.2823565, 39.9246572, -84.6444073, 44.1942214],
  },
  omaha: {
    archive: 'Omaha.zip',
    filename: 'Omaha SEC.tif',
    bounding_box: [-101.306099, 39.923674, -92.6249366, 44.5285109],
  },
  cheyenne: {
    archive: 'Cheyenne.zip',
    filename: 'Cheyenne SEC.tif',
    bounding_box: [-109.3076224, 39.9251044, -100.6185816, 44.5272313],
  },
  salt_lake_city: {
    archive: 'Salt_Lake_City.zip',
    filename: 'Salt Lake City SEC.tif',
    bounding_box: [-117.3055726, 39.9249412, -108.6206512, 44.5236113],
  },
  klamath_falls: {
    archive: 'Klamath_Falls.zip',
    filename: 'Klamath Falls SEC.tif',
    bounding_box: [-125.3061451, 39.92517, -116.6270444, 44.5294905],
  },

  washington: {
    archive: 'Washington.zip',
    filename: 'Washington SEC.tif',
    bounding_box: [-79.1966861, 35.9465606, -71.6596589, 40.2243358],
  },
  cincinnati: {
    archive: 'Cincinnati.zip',
    filename: 'Cincinnati SEC.tif',
    bounding_box: [-85.1957193, 35.9467387, -77.7170835, 40.2402541],
  },
  st_louis: {
    archive: 'St_Louis.zip',
    filename: 'St Louis SEC.tif',
    bounding_box: [-91.1972622, 35.9492499, -83.7443011, 40.241944],
  },
  kansas_city: {
    archive: 'Kansas_City.zip',
    filename: 'Kansas City SEC.tif',
    bounding_box: [-97.2004249, 35.9495873, -89.7146753, 40.2262392],
  },
  wichita: {
    archive: 'Wichita.zip',
    filename: 'Wichita SEC.tif',
    bounding_box: [-104.1948413, 35.9454468, -96.6296011, 40.2372955],
  },
  denver: {
    archive: 'Denver.zip',
    filename: 'Denver SEC.tif',
    bounding_box: [-111.2076127, 35.5835769, -103.7323775, 40.0675584],
  },
  las_vegas: {
    archive: 'Las_Vegas.zip',
    filename: 'Las Vegas SEC.tif',
    bounding_box: [-118.2078426, 35.5815239, -110.70019, 40.0657608],
  },
  san_francisco: {
    archive: 'San_Francisco.zip',
    filename: 'San Francisco SEC.tif',
    bounding_box: [-125.2006604, 35.9470132, -117.6527801, 40.2085448],
  },

  charlotte: {
    archive: 'Charlotte.zip',
    filename: 'Charlotte SEC.tif',
    bounding_box: [-82.1732607, 31.947316, -74.9435421, 36.2357435],
  },
  atlanta: {
    archive: 'Atlanta.zip',
    filename: 'Atlanta SEC.tif',
    bounding_box: [-88.186108, 31.9475007, -80.7759948, 36.2090096],
  },
  memphis: {
    archive: 'Memphis.zip',
    filename: 'Memphis SEC.tif',
    bounding_box:  [-95.1861902, 31.9467178, -87.7739182, 36.2327687],
  },
  dallas_ft_worth: {
    archive: 'Dallas-Ft_Worth.zip',
    filename: 'Dallas-Ft Worth SEC.tif',
    bounding_box: [-102.1862045, 31.9476892, -94.779702, 36.2234347],
  },
  albuquerque: {
    archive: 'Albuquerque.zip',
    filename: 'Albuquerque SEC.tif',
    bounding_box: [-109.1831905, 31.9460701, -101.781149, 36.2243607],
  },
  phoenix: {
    archive: 'Phoenix.zip',
    filename: 'Phoenix SEC.tif',
    bounding_box: [-116.1910631, 31.2658758, -108.747054, 35.6914429],
  },
  los_angeles: {
    archive: 'Los_Angeles.zip',
    filename: 'Los Angeles SEC.tif',
    bounding_box: [-122.3105084, 31.9412668, -114.5508769, 36.0875941],
  },

  jacksonville: {
    archive: 'Jacksonville.zip',
    filename: 'Jacksonville SEC.tif',
    bounding_box: [-85.1212828, 27.9588144, -78.433951, 32.242651],
  },
  new_orleans: {
    archive: 'New_Orleans.zip',
    filename: 'New Orleans SEC.tif',
    bounding_box: [-91.1189459, 27.9582419, -84.4427018, 32.2342433],
  },
  houston: {
    archive: 'Houston.zip',
    filename: 'Houston SEC.tif',
    bounding_box: [-97.1209012, 27.9598658, -90.4496381, 32.2323637],
  },
  san_antonio: {
    archive: 'San_Antonio.zip',
    filename: 'San Antonio SEC.tif',
    bounding_box: [-103.1214652, 27.9562038, -96.3603537, 32.2371014],
  },
  el_paso: {
    archive: 'El_Paso.zip',
    filename: 'El Paso SEC.tif',
    bounding_box: [-109.118829, 27.9576038, -102.4444274, 32.2345108],
  },

  miami: {
    archive: 'Miami.zip',
    filename: 'Miami SEC.tif',
    bounding_box: [-83.1276045, 23.9578706, -76.3371967, 28.495424],
  },
  brownsville: {
    archive: 'Brownsville.zip',
    filename: 'Brownsville SEC.tif',
    bounding_box: [-103.1163639, 23.9624798, -96.5794134, 28.2381364],
  },

  # Alaska
  point_barrow: {
    archive: 'Point_Barrow.zip',
    filename: 'Point Barrow SEC.tif',
    bounding_box: [-158.7307989, 67.8047005, -139.1501914, 72.0988825],
  },
  cape_lisburne: {
    archive: 'Cape_Lisburne.zip',
    filename: 'Cape Lisburne SEC.tif',
    bounding_box: [-172.9684675, 67.8051495, -154.9510469, 72.1227863],
  },
  dawson: {
    archive: 'Dawson.zip',
    filename: 'Dawson SEC.tif',
    bounding_box: [-146.1671105, 63.849068, -130.7247982, 68.1250495],
  },
  fairbanks: {
    archive: 'Fairbanks.zip',
    filename: 'Fairbanks SEC.tif',
    bounding_box: [-159.1682847, 63.8493161, -143.7323474, 68.1276488],
  },
  nome: {
    archive: 'Nome.zip',
    filename: 'Nome SEC.tif',
    bounding_box: [-172.7098028, 63.8369072, -156.6617338, 68.1168622],
  },
  anchorage: {
    archive: 'Anchorage.zip',
    filename: 'Anchorage SEC.tif',
    bounding_box: [-152.2420725, 59.8603386, -139.3449105, 64.1570625],
  },
  mcgrath: {
    archive: 'McGrath.zip',
    filename: 'McGrath SEC.tif',
    bounding_box: [-162.740768, 59.8624277, -149.8954106, 64.1517769],
  },
  bethel: {
    archive: 'Bethel.zip',
    filename: 'Bethel SEC.tif',
    bounding_box: [-173.8722179, 59.5538338, -160.3211795, 64.1442169],
  },
  seward: {
    archive: 'Seward.zip',
    filename: 'Seward SEC.tif',
    bounding_box: [-152.9265913, 59.0894754, -139.9579931, 61.4556512],
  },
  juneau: {
    archive: 'Juneau.zip',
    filename: 'Juneau SEC.tif',
    bounding_box: [-141.6968685, 55.8732122, -129.7110844, 60.1621043],
  },
  kodiak: {
    archive: 'Kodiak.zip',
    filename: 'Kodiak SEC.tif',
    bounding_box: [-162.6613995, 55.6030899, -150.7055431, 60.1491559],
  },
  ketchikan: {
    archive: 'Ketchikan.zip',
    filename: 'Ketchikan SEC.tif',
    bounding_box: [-139.4593378, 51.9058426, -129.257354, 56.1592074],
  },
  cold_bay: {
    archive: 'Cold_Bay.zip',
    filename: 'Cold Bay SEC.tif',
    bounding_box: [-164.2556053, 53.834451, -154.0860067, 56.1693458],
  },
  dutch_harbor: {
    archive: 'Dutch_Harbor.zip',
    filename: 'Dutch Harbor SEC.tif',
    bounding_box: [-173.4594969, 51.9004498, -163.0941263, 56.1594243],
  },
  western_aleutian_islands_east_east: {
    archive: 'Western_Aleutian_Islands.zip',
    filename: 'Western Aleutian Islands East SEC.tif',
    bounding_box: [-180, 50.8982375, -172.5, 53.178477],
  },
  western_aleutian_islands_east_west: {
    archive: 'Western_Aleutian_Islands.zip',
    filename: 'Western Aleutian Islands East SEC.tif',
    bounding_box: [178, 50.9407542, 180, 53.1807219],
  },
  western_aleutian_islands_west: {
    archive: 'Western_Aleutian_Islands.zip',
    filename: 'Western Aleutian Islands West SEC.tif',
    bounding_box: [169.1578182, 51.00103, 178.6440813, 53.2029588],
  },

  # Pacific Ocean
  hawaiian_islands: {
    archive: 'Hawaiian_Islands.zip',
    filename: 'Hawaiian Islands SEC.tif',
    bounding_box: [-160.9800227, 18.3545464, -154.02883, 23.5970193],
    insets: {
      honolulu: 'Honolulu Inset SEC.tif',
      mariana_islands: 'Mariana Islands Inset SEC.tif',
      samoan_islands: 'Samoan Islands Inset SEC.tif',
    },
  },
  honolulu: {
    inset: true,
    bounding_box: [-158.4912572, 20.7631674, -157.3545251, 21.6098562],
  },
  mariana_islands: {
    inset: true,
    bounding_box: [142.911771, 12.6623105, 146.5422288, 16.1119794],
  },
  samoan_islands: {
    inset: true,
    bounding_box: [-172.8623512, -14.6831695, -169.3523915, -13.1947756],
  },
}

Rails.configuration.terminal_area_charts = {
  anchorage: {
    archive: 'Anchorage-Fairbanks_TAC.zip',
    filename: 'Anchorage TAC.tif',
    bounding_box: [-151.8516301, 60.5517718, -148.3003135, 61.6727378],
    insets: {
      fairbanks: 'Fairbanks TAC.tif',
    },
  },
  atlanta: {
    archive: 'Atlanta_TAC.zip',
    filename: 'Atlanta TAC.tif',
    bounding_box: [-85.3048957, 32.9778844, -83.5965255, 34.3112784],
  },
  baltimore_washington: {
    archive: 'Baltimore-Washington_TAC.zip',
    filename: 'Baltimore-Washington TAC.tif',
    bounding_box: [-78.3421974, 38.1830542, -75.7553136, 39.8023634],
  },
  boston: {
    archive: 'Boston_TAC.zip',
    filename: 'Boston TAC.tif',
    bounding_box: [-71.8733667, 41.2476905, -69.5603656, 42.8742916],
  },
  charlotte: {
    archive: 'Charlotte_TAC.zip',
    filename: 'Charlotte TAC.tif',
    bounding_box: [-81.8282408, 34.5833994, -80.0862537, 35.9008349],
  },
  chicago: {
    archive: 'Chicago_TAC.zip',
    filename: 'Chicago TAC.tif',
    bounding_box: [-88.7757696, 41.4572573, -87.2518728, 42.4901428],
  },
  cincinnati: {
    archive: 'Cincinnati_TAC.zip',
    filename: 'Cincinnati TAC.tif',
    bounding_box: [-85.5405505, 38.4717674, -83.6928206, 40.0749323],
  },
  cleveland: {
    archive: 'Cleveland_TAC.zip',
    filename: 'Cleveland TAC.tif',
    bounding_box: [-82.6014373, 40.8682083, -81.088485, 41.9031376],
  },
  colorado_springs: {
    inset: true,
    bounding_box: [-105.5162259, 37.8004233, -103.4843933, 39.27071],
  },
  dallas_ft_worth: {
    archive: 'Dallas-Ft_Worth_TAC.zip',
    filename: 'Dallas-Ft Worth TAC.tif',
    bounding_box: [-98.2233784, 32.050715, -95.8769571, 33.6718573],
  },
  denver: {
    archive: 'Denver_TAC.zip',
    filename: 'Denver TAC.tif',
    bounding_box: [-105.5855181, 39.2433985, -103.7238348, 40.5708504],
    insets: {
      colorado_springs: 'Colorado Springs TAC.tif',
    },
  },
  detroit: {
    archive: 'Detroit_TAC.zip',
    filename: 'Detroit TAC.tif',
    bounding_box: [-84.2857616, 41.630271, -82.3795235, 42.8597209],
  },
  fairbanks: {
    inset: true,
    bounding_box: [-149.3673749, 64.1658271, -145.7100148, 65.2602783],
  },
  houston: {
    archive: 'Houston_TAC.zip',
    filename: 'Houston TAC.tif',
    bounding_box: [-96.1452368, 29.0897682, -94.5135729, 30.509192],
  },
  kansas_city: {
    archive: 'Kansas_City_TAC.zip',
    filename: 'Kansas City TAC.tif',
    bounding_box: [-95.9112782, 38.7339957, -94.0680001, 39.998105],
  },
  las_vegas: {
    archive: 'Las_Vegas_TAC.zip',
    filename: 'Las Vegas TAC.tif',
    bounding_box: [-115.6203448, 35.6962243, -113.8644214, 36.7345017],
  },
  los_angeles: {
    archive: 'Los_Angeles_TAC.zip',
    filename: 'Los Angeles TAC.tif',
    bounding_box: [-119.1504461, 33.4105318, -116.7925499, 34.5224602],
  },
  memphis: {
    archive: 'Memphis_TAC.zip',
    filename: 'Memphis TAC.tif',
    bounding_box: [-90.8645351, 34.4014646, -89.1178876, 35.7102965],
  },
  miami: {
    archive: 'Miami_TAC.zip',
    filename: 'Miami TAC.tif',
    bounding_box: [-81.181655, 25.1155823, -79.3210118, 26.7664465],
  },
  minneapolis_st_paul: {
    archive: 'Minneapolis-St_Paul_TAC.zip',
    filename: 'Minneapolis-St Paul TAC.tif',
    bounding_box: [-94.0361575, 44.3551402, -92.4457485, 45.3839341],
  },
  new_orleans: {
    archive: 'New_Orleans_TAC.zip',
    filename: 'New Orleans TAC.tif',
    bounding_box: [-91.2848934, 29.5577589, -89.6580516, 30.5846693],
  },
  new_york: {
    archive: 'New_York_TAC.zip',
    filename: 'New York TAC.tif',
    bounding_box: [-74.902063, 40.2138327, -72.6425346, 41.266109],
  },
  orlando: {
    inset: true,
    bounding_box: [-82.0286892, 27.8298116, -80.1422994, 29.1889221],
  },
  philadelphia: {
    archive: 'Philadelphia_TAC.zip',
    filename: 'Philadelphia TAC.tif',
    bounding_box: [-75.9869525, 39.3770881, -74.5057707, 40.5027674],
  },
  phoenix: {
    archive: 'Phoenix_TAC.zip',
    filename: 'Phoenix TAC.tif',
    bounding_box: [-112.8695473, 32.7832066, -111.1685184, 34.0867795],
  },
  pittsburgh: {
    archive: 'Pittsburgh_TAC.zip',
    filename: 'Pittsburgh TAC.tif',
    bounding_box: [-80.9658889, 39.9684073, -79.4755719, 41.0025079],
  },
  puerto_rico: {
    archive: 'Puerto_Rico-VI_TAC.zip',
    filename: 'Puerto Rico-VI TAC.tif',
    bounding_box: [-67.514356, 17.6384252, -64.2392412, 18.7898181],
  },
  salt_lake_city: {
    archive: 'Salt_Lake_City_TAC.zip',
    filename: 'Salt Lake City TAC.tif',
    bounding_box: [-112.9074313, 40.1215692, -111.0248773, 41.4195385],
  },
  san_diego: {
    archive: 'San_Diego_TAC.zip',
    filename: 'San Diego TAC.tif',
    bounding_box: [-117.9803061, 32.5006575, -116.2888088, 33.6139202],
  },
  san_francisco: {
    archive: 'San_Francisco_TAC.zip',
    filename: 'San Francisco TAC.tif',
    bounding_box: [-123.1629807, 37.0079706, -121.3713683, 38.1914785],
  },
  seattle: {
    archive: 'Seattle_TAC.zip',
    filename: 'Seattle TAC.tif',
    bounding_box: [-123.1970428, 46.7508517, -121.5299795, 48.0632155],
  },
  st_louis: {
    archive: 'St_Louis_TAC.zip',
    filename: 'St Louis TAC.tif',
    bounding_box: [-91.0762958, 38.1829259, -89.6231055, 39.2207447],
  },
  tampa: {
    archive: 'Tampa-Orlando_TAC.zip',
    filename: 'Tampa TAC.tif',
    bounding_box: [-83.0958004, 27.2921468, -81.8288128, 28.5966997],
    insets: {
      orlando: 'Orlando TAC.tif'
    },
  },
}

Rails.configuration.caribbean_charts = {
  caribbean_1: {
    archive: 'Caribbean_1_VFR.zip',
    filename: 'Caribbean 1 VFR Chart.tif',
    bounding_box: [-85.4799295, 16.0031192, -71.7328657, 27.5226193],
  },
  caribbean_2: {
    archive: 'Caribbean_2_VFR.zip',
    filename: 'Caribbean 2 VFR Chart.tif',
    bounding_box: [-73.2298992, 14.0020451, -60.2281204, 22.2515826],
  },
}

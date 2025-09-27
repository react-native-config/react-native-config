package com.lugg.RNCConfig;

import com.facebook.react.bridge.Arguments;
import com.facebook.react.bridge.WritableArray;
import com.facebook.react.bridge.WritableMap;
import java.util.List;
import java.util.Map;

class MapConverter {
  public static WritableMap convertMapToWritableMap(Map<String, Object> sourceMap) {
    WritableMap writableMap = Arguments.createMap();
    if (sourceMap == null) {
      return writableMap; // Return empty map if source is null
    }

    for (Map.Entry<String, Object> entry : sourceMap.entrySet()) {
      String key = entry.getKey();
      Object value = entry.getValue();
      putValueInMap(writableMap, key, value);
    }
    return writableMap;
  }

  private static void putValueInMap(WritableMap map, String key, Object value) {
    if (value == null) {
      map.putNull(key);
    } else if (value instanceof String) {
      map.putString(key, (String) value);
    } else if (value instanceof Integer) {
      map.putInt(key, (Integer) value);
    } else if (value instanceof Long) {
      map.putLong(key, (Long) value);
    } else if (value instanceof Double) {
      map.putDouble(key, (Double) value);
    } else if (value instanceof Float) {
      map.putDouble(key, (Float) value); // Float to double
    } else if (value instanceof Boolean) {
      map.putBoolean(key, (Boolean) value);
    } else if (value instanceof Map) {
      @SuppressWarnings("unchecked")
      Map<String, Object> nestedMap = (Map<String, Object>) value;
      map.putMap(key, convertMapToWritableMap(nestedMap));
    } else if (value instanceof List) {
      @SuppressWarnings("unchecked")
      List<Object> list = (List<Object>) value;
      WritableArray writableArray = convertListToWritableArray(list);
      map.putArray(key, writableArray);
    } else {
      // Fallback for unsupported types: convert to string or handle as needed
      map.putString(key, value.toString());
    }
  }

  private static WritableArray convertListToWritableArray(List<Object> sourceList) {
    WritableArray writableArray = Arguments.createArray();
    if (sourceList == null) {
      return writableArray;
    }

    for (Object item : sourceList) {
      if (item == null) {
        writableArray.pushNull();
      } else if (item instanceof String) {
        writableArray.pushString((String) item);
      } else if (item instanceof Integer) {
        writableArray.pushInt((Integer) item);
      } else if (item instanceof Long) {
        writableArray.pushInt(((Long) item).intValue()); // Or use custom handling
      } else if (item instanceof Double) {
        writableArray.pushDouble((Double) item);
      } else if (item instanceof Float) {
        writableArray.pushDouble((Float) item);
      } else if (item instanceof Boolean) {
        writableArray.pushBoolean((Boolean) item);
      } else if (item instanceof Map) {
        @SuppressWarnings("unchecked")
        Map<String, Object> nestedMap = (Map<String, Object>) item;
        writableArray.pushMap(convertMapToWritableMap(nestedMap));
      } else if (item instanceof List) {
        @SuppressWarnings("unchecked")
        List<Object> nestedList = (List<Object>) item;
        writableArray.pushArray(convertListToWritableArray(nestedList));
      } else {
        // Fallback
        writableArray.pushString(item.toString());
      }
    }
    return writableArray;
  }
}

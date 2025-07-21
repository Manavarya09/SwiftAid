import React from 'react';
import { View, Text, TextInput, StyleSheet } from 'react-native';

interface NumericInputProps {
  label: string;
  value: string;
  onValueChange: (text: string) => void;
  power: string;
  onPowerChange: (text: string) => void;
}

const NumericInput: React.FC<NumericInputProps> = ({ label, value, onValueChange, power, onPowerChange }) => {
  return (
    <View style={styles.inputContainer}>
      <Text style={styles.label}>{label}:</Text>
      <TextInput
        style={styles.input}
        value={value}
        onChangeText={onValueChange}
        keyboardType="numeric"
      />
      <Text style={styles.multiplier}>x10^</Text>
      <TextInput
        style={styles.powerInput}
        value={power}
        onChangeText={onPowerChange}
        keyboardType="numeric"
      />
    </View>
  );
};

const styles = StyleSheet.create({
  inputContainer: {
    flexDirection: 'row',
    alignItems: 'center',
    marginBottom: 15,
  },
  label: {
    fontSize: 18,
    marginRight: 10,
    width: 95,
  },
  input: {
    width: 100,
    height: 40,
    borderColor: 'gray',
    borderWidth: 1,
    paddingHorizontal: 10,
    borderRadius: 5,
    backgroundColor: 'white',
  },
  multiplier: {
    fontSize: 18,
    marginHorizontal: 5,
  },
  powerInput: {
    width: 50,
    height: 40,
    borderColor: 'gray',
    borderWidth: 1,
    paddingHorizontal: 10,
    borderRadius: 5,
    backgroundColor: 'white',
  },
});

export default NumericInput; 
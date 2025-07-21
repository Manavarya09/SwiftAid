import React, { useState, useRef } from 'react';
import { View, Text, TextInput, Button, StyleSheet, ScrollView, ActivityIndicator } from 'react-native';
import { WebView } from 'react-native-webview';
import NumericInput from '../components/NumericInput';

const HelmholtzScreen = () => {
  // --- STATE VARIABLES ---
  const [I, setI] = useState('1');
  const [Ic, setIc] = useState('1');
  const [amax, setAmax] = useState('100');
  const [amaxPower, setAmaxPower] = useState('-3');
  const [h, setH] = useState('50');
  const [xt, setXt] = useState('0');
  const [yt, setYt] = useState('0');
  const [zt, setZt] = useState('0');
  const [Nr, setNr] = useState('5');
  const [R, setR] = useState('25');
  const [xlim, setXlim] = useState('100');
  const [f, setF] = useState('6.78');
  const [fPower, setFPower] = useState('6');
  const [resolution, setResolution] = useState('20');
  
  const [loading, setLoading] = useState(false);
  const [plotsVisible, setPlotsVisible] = useState(false);
  const [progress, setProgress] = useState(0);
  const [isWebViewLoaded, setWebViewLoaded] = useState(false);
  const [pendingCalculation, setPendingCalculation] = useState<any>(null);
  const webviewRef = useRef<WebView>(null);

  // --- HANDLERS ---
  const handleCalculate = () => {
    setLoading(true);
    setPlotsVisible(true);
    setProgress(0);

    const params = {
      I: parseFloat(I),
      Ic: parseFloat(Ic),
      amax: parseFloat(amax) * Math.pow(10, parseInt(amaxPower, 10)),
      h: parseFloat(h) / 1000,
      xt: parseFloat(xt),
      yt: parseFloat(yt),
      zt: parseFloat(zt),
      Nr: parseInt(Nr, 10),
      R: parseInt(R, 10),
      xlim: parseInt(xlim, 10),
      f: parseFloat(f) * Math.pow(10, parseInt(fPower, 10)),
      resolution: parseInt(resolution, 10),
    };

    // Parameter validation
    for (const [key, value] of Object.entries(params)) {
      if (typeof value !== 'number' || isNaN(value)) {
        alert(`Invalid value for ${key}: ${value}`);
        setLoading(false);
        return;
      }
    }
    
    if (isWebViewLoaded) {
      webviewRef.current?.postMessage(JSON.stringify({ type: 'calculate', payload: params }));
    } else {
      setPendingCalculation(params);
    }
  };
  
  const onMessage = (event: any) => {
    const data = JSON.parse(event.nativeEvent.data);
    if (data.type === 'calculation_done') {
      setLoading(false);
      setProgress(100);
    } else if (data.type === 'progress') {
      setProgress(data.payload);
    } else if (data.type === 'error') {
      console.error("Calculation Error from WebView:", data.payload);
      setLoading(false);
    }
  };

  const onWebViewLoadEnd = () => {
    setWebViewLoaded(true);
    if (pendingCalculation) {
      webviewRef.current?.postMessage(JSON.stringify({ type: 'calculate', payload: pendingCalculation }));
      setPendingCalculation(null);
    }
  };

  // --- WEBVIEW CONTENT ---
  const staticHtml = `
      <html>
        <head>
          <script src="https://cdn.plot.ly/plotly-latest.min.js"></script>
        </head>
        <body>
          <div id="plotHx"></div>
          <div id="plotHy"></div>
          <div id="plotHz"></div>
          <div id="plotVind"></div>
        </body>
      </html>
  `;
  
  const injectedJavaScript = `
    const calculateHelmholtz = (params, onProgress) => {
      const { Nr, R, I, Ic, amax, h, xt, yt, zt, xlim, f, resolution } = params;

      const conv2_full = (A, B) => {
        const A_rows = A.length;
        const A_cols = A[0].length;
        const B_rows = B.length;
        const B_cols = B[0].length;

        const C_rows = A_rows + B_rows - 1;
        const C_cols = A_cols + B_cols - 1;

        const C = Array(C_rows).fill(0).map(() => Array(C_cols).fill(0));
        
        const total_conv_steps = A_rows * A_cols;
        let conv_step = 0;

        for (let i = 0; i < A_rows; i++) {
            for (let j = 0; j < A_cols; j++) {
                conv_step++;
                const progress_interval = Math.floor(total_conv_steps / 20);
                if (progress_interval > 0 && (conv_step % progress_interval === 0 || conv_step === total_conv_steps)) {
                    onProgress(50 + Math.round((conv_step / total_conv_steps) * 50));
                } else if (progress_interval === 0 && conv_step === total_conv_steps) {
                    onProgress(100);
                }
                if (A[i][j] !== 0) {
                    for (let m = 0; m < B_rows; m++) {
                        for (let n = 0; n < B_cols; n++) {
                            C[i + m][j + n] += A[i][j] * B[m][n];
                        }
                    }
                }
            }
        }
        return C;
      };
      
      const meshgrid = (x_ax, y_ax) => {
        const X_grid = Array(y_ax.length).fill(0).map(() => Array(x_ax.length).fill(0));
        const Y_grid = Array(y_ax.length).fill(0).map(() => Array(y_ax.length).fill(0));
        for (let i = 0; i < y_ax.length; i++) {
            for (let j = 0; j < x_ax.length; j++) {
                X_grid[i][j] = x_ax[j];
                Y_grid[i][j] = y_ax[i];
            }
        }
        return [X_grid, Y_grid];
      };

      const dx = resolution;
      const dy = resolution;
      const mu_o = 4 * Math.PI * 1e-7;
      const mu_r = 1;
      const k = (mu_o * mu_r * I * Ic) / (4 * Math.PI);
      const z = h - zt;
      const ylim = xlim;
      const x = [];
      for(let i = -xlim; i <= xlim; i += dx) { x.push(i * 1e-3); }
      const y = [];
      for(let i = -ylim; i <= ylim; i += dy) { y.push(i * 1e-3); }
      const a = amax;
      const Hx = Array(y.length).fill(0).map(() => Array(x.length).fill(0));
      const Hy = Array(y.length).fill(0).map(() => Array(x.length).fill(0));
      const Hz = Array(y.length).fill(0).map(() => Array(x.length).fill(0));

      const total_field_steps = x.length * y.length;
      let field_step = 0;

      for (let i = 0; i < x.length; i++) {
        for (let j = 0; j < y.length; j++) {
          field_step++;
          const progress_interval = Math.floor(total_field_steps / 20);
          if (progress_interval > 0 && (field_step % progress_interval === 0 || field_step === total_field_steps)) {
            const progress = Math.round((field_step / total_field_steps) * 50);
            onProgress(progress);
          } else if (progress_interval === 0 && field_step === total_field_steps) {
            onProgress(50);
          }
          
          const X1 = x[i] - (xt + a);
          const X2 = x[i] - (xt - a);
          const Y1 = y[j] - (yt + a);
          const Y2 = y[j] - (yt - a);

          const B1x = ((k * z) / (X1 * X1 + z * z)) * ((Y2 / Math.sqrt(X1 * X1 + Y2 * Y2 + z * z)) - (Y1 / Math.sqrt(X1 * X1 + Y1 * Y1 + z * z)));
          const B3x = ((k * z) / (X2 * X2 + z * z)) * ((Y1 / Math.sqrt(X2 * X2 + Y1 * Y1 + z * z)) - (Y2 / Math.sqrt(X2 * X2 + Y2 * Y2 + z * z)));
          const Bx = B1x + B3x;
          Hx[j][i] = Bx / (mu_o * mu_r);

          const B2y = ((k * z) / (Y1 * Y1 + z * z)) * ((X2 / Math.sqrt(X2 * X2 + Y1 * Y1 + z * z)) - (X1 / Math.sqrt(X1 * X1 + Y1 * Y1 + z * z)));
          const B4y = ((k * z) / (Y2 * Y2 + z * z)) * ((X1 / Math.sqrt(X1 * X1 + Y2 * Y2 + z * z)) - (X2 / Math.sqrt(X2 * X2 + Y2 * Y2 + z * z)));
          const By = B2y + B4y;
          Hy[j][i] = By / (mu_o * mu_r);

          const B1z = ((k * X1) / (X1 * X1 + z * z)) * ((Y1 / Math.sqrt(X1 * X1 + Y1 * Y1 + z * z)) - (Y2 / Math.sqrt(X1 * X1 + Y2 * Y2 + z * z)));
          const B2z = ((k * Y1) / (Y1 * Y1 + z * z)) * ((X1 / Math.sqrt(X1 * X1 + Y1 * Y1 + z * z)) - (X2 / Math.sqrt(X2 * X2 + Y1 * Y1 + z * z)));
          const B3z = ((k * X2) / (X2 * X2 + z * z)) * ((Y2 / Math.sqrt(X2 * X2 + Y2 * Y2 + z * z)) - (Y1 / Math.sqrt(X2 * X2 + Y1 * Y1 + z * z)));
          const B4z = ((k * Y2) / (Y2 * Y2 + z * z)) * ((X2 / Math.sqrt(X2 * X2 + Y2 * Y2 + z * z)) - (X1 / Math.sqrt(X1 * X1 + Y2 * Y2 + z * z)));
          const Bz = B1z + B2z + B3z + B4z;
          Hz[j][i] = Bz / (mu_o * mu_r);
        }
      }

      const [X, Y] = meshgrid(x, y);

      const xs = [];
      const R_mm = R;
      for(let i = -(R_mm + xlim); i <= (R_mm + xlim); i += dx) { xs.push(i); }
      const ys = xs;
      const [Xs, Ys] = meshgrid(xs, ys);

      const w = 2 * Math.PI * f;
      const dA = (dx * 1e-3) * (dy * 1e-3);
      const Ars = Array(Math.floor(2 * R_mm / dy) + 1).fill(0).map(() => Array(Math.floor(2 * R_mm / dx) + 1).fill(Nr));
      
      const convResult = conv2_full(Hz, Ars);
      const Vind = convResult.map(row => row.map(val => w * mu_o * val * dA));

      return { X, Y, Hx, Hy, Hz, Xs, Ys, Vind };
    };

    const plotResults = (data) => {
        const { X, Y, Hx, Hy, Hz, Xs, Ys, Vind } = data;
        const plotOptions = { margin: { l: 0, r: 0, b: 0, t: 0 } };

        Plotly.newPlot('plotHx', [{ z: Hx, x: X[0], y: Y.map(row => row[0]), type: 'surface' }], { ...plotOptions, title: 'Hx Component' });
        Plotly.newPlot('plotHy', [{ z: Hy, x: X[0], y: Y.map(row => row[0]), type: 'surface' }], { ...plotOptions, title: 'Hy Component' });
        Plotly.newPlot('plotHz', [{ z: Hz, x: X[0], y: Y.map(row => row[0]), type: 'surface' }], { ...plotOptions, title: 'Hz Component' });
        Plotly.newPlot('plotVind', [{ z: Vind, x: Xs[0], y: Ys.map(row => row[0]), type: 'surface' }], { ...plotOptions, title: 'Induced Voltage (Vind)' });
    };

    window.addEventListener('message', event => {
        const { type, payload } = JSON.parse(event.data);
        if (type === 'calculate') {
            try {
                const onProgress = (progress) => {
                  window.ReactNativeWebView.postMessage(JSON.stringify({ type: 'progress', payload: progress }));
                };
                const results = calculateHelmholtz(payload, onProgress);
                plotResults(results);
                window.ReactNativeWebView.postMessage(JSON.stringify({ type: 'calculation_done' }));
            } catch (e) {
                window.ReactNativeWebView.postMessage(JSON.stringify({ type: 'error', payload: e.toString() }));
            }
        }
    });
    true;
  `;

  // --- RENDER ---
  return (
    <ScrollView contentContainerStyle={styles.container}>
      <Text style={styles.title}>Helmholtz Tx - Helmholtz Rx</Text>
      
      <Text style={styles.sectionTitle}>Transmitter Parameters</Text>
      <View style={styles.inputContainer}><Text style={styles.label}>I (A):</Text><TextInput style={styles.input} value={I} onChangeText={setI} keyboardType="numeric" /></View>
      <View style={styles.inputContainer}><Text style={styles.label}>Ic (A):</Text><TextInput style={styles.input} value={Ic} onChangeText={setIc} keyboardType="numeric" /></View>
      <NumericInput label="amax (m)" value={amax} onValueChange={setAmax} power={amaxPower} onPowerChange={setAmaxPower} />
      <View style={styles.inputContainer}><Text style={styles.label}>h (mm):</Text><TextInput style={styles.input} value={h} onChangeText={setH} keyboardType="numeric" /></View>
      <View style={styles.inputContainer}><Text style={styles.label}>xt (m):</Text><TextInput style={styles.input} value={xt} onChangeText={setXt} keyboardType="numeric" /></View>
      <View style={styles.inputContainer}><Text style={styles.label}>yt (m):</Text><TextInput style={styles.input} value={yt} onChangeText={setYt} keyboardType="numeric" /></View>
      <View style={styles.inputContainer}><Text style={styles.label}>zt (m):</Text><TextInput style={styles.input} value={zt} onChangeText={setZt} keyboardType="numeric" /></View>

      <Text style={styles.sectionTitle}>Receiver Parameters</Text>
      <View style={styles.inputContainer}><Text style={styles.label}>Nr:</Text><TextInput style={styles.input} value={Nr} onChangeText={setNr} keyboardType="numeric" /></View>
      <View style={styles.inputContainer}><Text style={styles.label}>R (mm):</Text><TextInput style={styles.input} value={R} onChangeText={setR} keyboardType="numeric" /></View>

      <Text style={styles.sectionTitle}>Simulation Parameters</Text>
      <View style={styles.inputContainer}><Text style={styles.label}>xlim (mm):</Text><TextInput style={styles.input} value={xlim} onChangeText={setXlim} keyboardType="numeric" /></View>
      <NumericInput label="Freq (Hz)" value={f} onValueChange={setF} power={fPower} onPowerChange={setFPower} />
      <View style={styles.inputContainer}><Text style={styles.label}>Resolution:</Text><TextInput style={styles.input} value={resolution} onChangeText={setResolution} keyboardType="numeric" /></View>
      <Text style={styles.infoText}>
        Note: A smaller Resolution value increases plot detail but also significantly increases calculation time.
      </Text>

      <Button title="Calculate and Plot" onPress={handleCalculate} disabled={loading} />
      {loading && (
        <View style={styles.loadingContainer}>
          <ActivityIndicator size="large" color="#0000ff" />
          <Text style={styles.progressText}>{progress}% Complete</Text>
        </View>
      )}
      
      <View style={plotsVisible ? styles.plotContainer : styles.hidden}>
          <WebView
            ref={webviewRef}
            originWhitelist={['*']}
            source={{ html: staticHtml }}
            style={styles.webview}
            onMessage={onMessage}
            injectedJavaScript={injectedJavaScript}
            javaScriptEnabled={true}
            domStorageEnabled={true}
            onLoadEnd={onWebViewLoadEnd}
          />
      </View>
    </ScrollView>
  );
};

const styles = StyleSheet.create({
  container: { flexGrow: 1, padding: 20, paddingTop: 50, backgroundColor: '#f5f5f5' },
  title: { fontSize: 24, fontWeight: 'bold', textAlign: 'center', marginBottom: 20 },
  sectionTitle: { fontSize: 20, fontWeight: 'bold', marginTop: 20, marginBottom: 10, borderBottomWidth: 1, borderBottomColor: '#ccc', paddingBottom: 5 },
  inputContainer: { flexDirection: 'row', alignItems: 'center', marginBottom: 15 },
  label: { fontSize: 18, marginRight: 10, width: 95 },
  input: { flex: 1, height: 40, borderColor: 'gray', borderWidth: 1, paddingHorizontal: 10, borderRadius: 5, backgroundColor: 'white' },
  plotContainer: { marginTop: 20, height: 800, borderWidth: 1, borderColor: '#ddd' },
  webview: { flex: 1 },
  hidden: { display: 'none' },
  loadingContainer: { alignItems: 'center', marginTop: 20 },
  progressText: { marginTop: 10, fontSize: 16 },
  infoText: {
    fontSize: 14,
    color: '#666',
    textAlign: 'center',
    marginBottom: 15,
    fontStyle: 'italic',
  },
});

export default HelmholtzScreen; 
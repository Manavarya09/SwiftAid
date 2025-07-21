interface CalculationParameters {
  Nr: number;
  R: number; // in mm
  I: number;
  Ic: number;
  amax: number; // in m
  h: number; // observation plane z, in m
  xt: number; // in m
  yt: number; // in m
  zt: number; // coil plane z, in m
  xlim: number; // in mm
  f: number;
  resolution: number;
}

export const calculateHelmholtz = (params: CalculationParameters, onProgress: (progress: number) => void) => {
  const conv2_full = (A: number[][], B: number[][]): number[][] => {
    const A_rows = A.length;
    const A_cols = A[0].length;
    const B_rows = B.length;
    const B_cols = B[0].length;

    const C_rows = A_rows + B_rows - 1;
    const C_cols = A_cols + B_cols - 1;

    const C: number[][] = Array(C_rows).fill(0).map(() => Array(C_cols).fill(0));
    
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
  
  const meshgrid = (x_ax: number[], y_ax: number[]): [number[][], number[][]] => {
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

  const { Nr, R, I, Ic, amax, h, xt, yt, zt, xlim, f, resolution } = params;

  const dx = resolution;
  const dy = resolution;
  const mu_o = 4 * Math.PI * 1e-7;
  const mu_r = 1;
  const k = (mu_o * mu_r * I * Ic) / (4 * Math.PI);
  const z = h - zt;
  const ylim = xlim;
  const x: number[] = [];
  for(let i = -xlim; i <= xlim; i += dx) { x.push(i * 1e-3); }
  const y: number[] = [];
  for(let i = -ylim; i <= ylim; i += dy) { y.push(i * 1e-3); }
  const a = amax;
  const Hx: number[][] = Array(y.length).fill(0).map(() => Array(x.length).fill(0));
  const Hy: number[][] = Array(y.length).fill(0).map(() => Array(x.length).fill(0));
  const Hz: number[][] = Array(y.length).fill(0).map(() => Array(x.length).fill(0));

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

  const xs: number[] = [];
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
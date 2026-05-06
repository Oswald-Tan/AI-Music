import axios from "axios";

const PYTHON_URL = process.env.PYTHON_SERVICE_URL || "http://localhost:8000";

const pythonApi = axios.create({
  baseURL: PYTHON_URL,
  timeout: 600000, // 10 minutes timeout for heavy AI processing
});

const fixUrls = (data) => {
  const backendUrl = process.env.BACKEND_URL || "http://localhost:8087";
  
  const processValue = (val) => {
    if (typeof val === 'string') {
      // Replace Python's localhost:8000
      let fixed = val.replace(/http:\/\/localhost:8000/g, backendUrl);
      // Prepend backendUrl to relative paths
      if (fixed.startsWith('/outputs') || fixed.startsWith('/uploads')) {
        fixed = `${backendUrl}${fixed}`;
      }
      return fixed;
    } else if (Array.isArray(val)) {
      return val.map(processValue);
    } else if (val !== null && typeof val === 'object') {
      const fixedObj = {};
      for (const key in val) {
        fixedObj[key] = processValue(val[key]);
      }
      return fixedObj;
    }
    return val;
  };

  return processValue(data);
};

export const separateAudio = async (filePath, jobId) => {
  try {
    const response = await pythonApi.post("/separate", { filePath, jobId });
    return fixUrls(response.data);
  } catch (error) {
    console.error("Error calling Python /separate:", error.message);
    throw error;
  }
};

export const detectChord = async (filePath, jobId) => {
  try {
    const response = await pythonApi.post("/chord", { filePath, jobId });
    return fixUrls(response.data);
  } catch (error) {
    console.error("Error calling Python /chord:", error.message);
    throw error;
  }
};

export const generateBeat = async (prompt) => {
  try {
    const response = await pythonApi.post("/beat", { prompt });
    return fixUrls(response.data);
  } catch (error) {
    console.error("Error calling Python /beat:", error.message);
    throw error;
  }
};

export const convertVoice = async (filePath, modelId) => {
  try {
    const response = await pythonApi.post("/voice", { filePath, modelId });
    return fixUrls(response.data);
  } catch (error) {
    console.error("Error calling Python /voice:", error.message);
    throw error;
  }
};

export const analyzeAudio = async (filePath, jobId) => {
  try {
    const response = await pythonApi.post("/analyze", { filePath, jobId });
    return fixUrls(response.data);
  } catch (error) {
    console.error("Error calling Python /analyze:", error.message);
    throw error;
  }
};

export const processAudio = async (filePath, tempo, pitch) => {
  try {
    const response = await pythonApi.post("/process", { filePath, tempo, pitch });
    return fixUrls(response.data);
  } catch (error) {
    console.error("Error calling Python /process:", error.message);
    throw error;
  }
};

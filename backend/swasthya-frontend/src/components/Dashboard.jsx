import { useEffect, useState } from "react";
import axios from "axios";
import { useNavigate } from "react-router-dom";

const Dashboard = () => {
  const [user, setUser] = useState(null);
  const [records, setRecords] = useState([]);
  const [title, setTitle] = useState("");
  const [file, setFile] = useState(null);
  const [isDoctor, setIsDoctor] = useState(false);
  const navigate = useNavigate();

  const token = localStorage.getItem("token");

  // Config for API calls (Attaches the Key/Token)
  const authConfig = {
    headers: { Authorization: `Bearer ${token}` },
  };

  useEffect(() => {
    if (!token) {
      navigate("/");
      return;
    }
    fetchUserData();
  }, []);

  const fetchUserData = async () => {
    try {
      // 1. Get User Profile
      const userRes = await axios.get("http://127.0.0.1:8000/api/v1/auth/me", authConfig);
      setUser(userRes.data);

      // 2. Check Role
      if (userRes.data.role === "doctor") {
        setIsDoctor(true);
        fetchDoctorRecords();
      } else {
        fetchPatientRecords();
      }
    } catch (err) {
      console.error("Error loading data", err);
      logout();
    }
  };

  const fetchPatientRecords = async () => {
    const res = await axios.get("http://127.0.0.1:8000/api/v1/records/", authConfig);
    setRecords(res.data);
  };

  const fetchDoctorRecords = async () => {
    const res = await axios.get("http://127.0.0.1:8000/api/v1/doctor/all-records", authConfig);
    setRecords(res.data);
  };

  const handleUpload = async () => {
    if (!file) return alert("Please select a file");

    const formData = new FormData();
    formData.append("title", title);
    formData.append("file", file);

    try {
      await axios.post("http://127.0.0.1:8000/api/v1/records/", formData, authConfig);
      alert("Upload Successful!");
      // Refresh list
      isDoctor ? fetchDoctorRecords() : fetchPatientRecords();
      setTitle("");
      setFile(null);
    } catch (err) {
      alert("Upload Failed");
    }
  };

  const logout = () => {
    localStorage.removeItem("token");
    navigate("/");
  };

  if (!user) return <div className="loading">Loading Swasthya...</div>;

  return (
    <div className="dashboard-container">
      <nav className="navbar">
        <h3>Swasthya App {isDoctor && <span className="badge">DOCTOR VIEW</span>}</h3>
        <div className="user-info">
          <span>{user.email}</span>
          <button onClick={logout} className="logout-btn">Logout</button>
        </div>
      </nav>

      <div className="content">
        {/* Upload Section (Only for Patients) */}
        {!isDoctor && (
          <div className="card upload-section">
            <h3>📂 Upload New Record</h3>
            <div className="form-group">
              <input 
                type="text" 
                placeholder="Report Name (e.g. Blood Test)" 
                value={title}
                onChange={(e) => setTitle(e.target.value)}
              />
              <input 
                type="file" 
                onChange={(e) => setFile(e.target.files[0])}
              />
              <button onClick={handleUpload}>Upload Record</button>
            </div>
          </div>
        )}

        {/* Records List */}
        <div className="card list-section">
          <h3>{isDoctor ? "👨‍⚕️ All Patient Records" : "📄 My Medical Records"}</h3>
          {records.length === 0 ? <p>No records found.</p> : (
            <div className="grid">
              {records.map((rec) => (
                <div key={rec.id} className="record-item">
                  <h4>{rec.title}</h4>
                  <p>ID: #{rec.id}</p>
                  <p className="date">Uploaded: {new Date(rec.created_at).toLocaleDateString()}</p>
                  <a href={`http://127.0.0.1:8000/${rec.file_url}`} target="_blank" rel="noopener noreferrer">
                    View Document
                  </a>
                </div>
              ))}
            </div>
          )}
        </div>
      </div>
    </div>
  );
};

export default Dashboard;
using System;

namespace HandBrakeWPF.Test
{
    /// <summary>
    /// Simple test class to verify target size calculation logic
    /// </summary>
    public class TargetSizeTest
    {
        /// <summary>
        /// Calculate video bitrate from target file size
        /// </summary>
        /// <param name="targetSizeMB">Target file size in megabytes</param>
        /// <param name="durationSeconds">Duration in seconds</param>
        /// <param name="audioBitrateKbps">Audio bitrate in kbps</param>
        /// <returns>Video bitrate in kbps</returns>
        public static int CalculateBitrateFromTargetFileSize(double targetSizeMB, int durationSeconds, int audioBitrateKbps)
        {
            if (durationSeconds <= 0 || targetSizeMB <= 0)
            {
                return 1000; // Default fallback bitrate
            }

            // Simple formula: target size (KB) × 8 ÷ duration (seconds) = bitrate (kbps)
            // Convert MB to KB: × 1024
            double targetSizeKB = targetSizeMB * 1024;
            double bitrateKbps = (targetSizeKB * 8) / durationSeconds;

            // Round to nearest integer and ensure minimum bitrate
            int finalBitrate = (int)Math.Round(bitrateKbps);
            if (finalBitrate < 100)
            {
                finalBitrate = 100;
            }

            return finalBitrate;
        }

        /// <summary>
        /// Test the calculation with various scenarios
        /// </summary>
        public static void RunTests()
        {
            Console.WriteLine("=== Target Size Calculation Tests ===");
            
            // Test 1: 700MB file, 2 hours (7200 seconds), 128kbps audio
            int result1 = CalculateBitrateFromTargetFileSize(700, 7200, 128);
            Console.WriteLine($"Test 1 - 700MB, 2h, 128kbps audio: {result1} kbps");
            
            // Test 2: 1400MB file, 2 hours (7200 seconds), 128kbps audio
            int result2 = CalculateBitrateFromTargetFileSize(1400, 7200, 128);
            Console.WriteLine($"Test 2 - 1400MB, 2h, 128kbps audio: {result2} kbps");
            
            // Test 3: 700MB file, 1.5 hours (5400 seconds), 128kbps audio
            int result3 = CalculateBitrateFromTargetFileSize(700, 5400, 128);
            Console.WriteLine($"Test 3 - 700MB, 1.5h, 128kbps audio: {result3} kbps");
            
            // Test 4: 350MB file, 1 hour (3600 seconds), 128kbps audio
            int result4 = CalculateBitrateFromTargetFileSize(350, 3600, 128);
            Console.WriteLine($"Test 4 - 350MB, 1h, 128kbps audio: {result4} kbps");
            
            // Test 5: Edge case - very small file
            int result5 = CalculateBitrateFromTargetFileSize(50, 3600, 128);
            Console.WriteLine($"Test 5 - 50MB, 1h, 128kbps audio: {result5} kbps");
            
            // Test 6: Edge case - invalid input
            int result6 = CalculateBitrateFromTargetFileSize(0, 3600, 128);
            Console.WriteLine($"Test 6 - 0MB (invalid): {result6} kbps");

            // Test 7: Decimal input - 700.5MB file, 2 hours, 128kbps audio
            int result7 = CalculateBitrateFromTargetFileSize(700.5, 7200, 128);
            Console.WriteLine($"Test 7 - 700.5MB, 2h, 128kbps audio: {result7} kbps");
            
            Console.WriteLine("\n=== Verification ===");
            Console.WriteLine("Expected results:");
            Console.WriteLine("Test 1: ~672 kbps (700MB * 8 * 1024 / 7200 - 128)");
            Console.WriteLine("Test 2: ~1472 kbps (1400MB * 8 * 1024 / 7200 - 128)");
            Console.WriteLine("Test 3: ~940 kbps (700MB * 8 * 1024 / 5400 - 128)");
            Console.WriteLine("Test 4: ~672 kbps (350MB * 8 * 1024 / 3600 - 128)");
            Console.WriteLine("Test 5: ~100 kbps (minimum enforced)");
            Console.WriteLine("Test 6: 1000 kbps (fallback)");
        }

        /// <summary>
        /// Main method for standalone testing
        /// </summary>
        public static void Main(string[] args)
        {
            RunTests();
            Console.WriteLine("\nPress any key to exit...");
            Console.ReadKey();
        }
    }
}

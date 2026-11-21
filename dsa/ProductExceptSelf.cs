// LeetCode 238 - Product of Array Except Self
// Both methods are included in one class for the assignment.

public class Solution
{
    // 5.1 Prefix[] + Suffix[] approach
    // Time Complexity: O(n)
    // Space Complexity: O(n) - prefix, suffix and output arrays.
    public int[] ProductExceptSelfPrefixSuffix(int[] nums)
    {
        int n = nums.Length;
        int[] prefix = new int[n];
        int[] suffix = new int[n];
        int[] answer = new int[n];

        prefix[0] = 1;
        for (int i = 1; i < n; i++)
        {
            prefix[i] = prefix[i - 1] * nums[i - 1];
        }

        suffix[n - 1] = 1;
        for (int i = n - 2; i >= 0; i--)
        {
            suffix[i] = suffix[i + 1] * nums[i + 1];
        }

        for (int i = 0; i < n; i++)
        {
            answer[i] = prefix[i] * suffix[i];
        }

        return answer;
    }

    // 5.2 Optimized approach: output array is not counted as extra space.
    // Time Complexity: O(n)
    // Extra Space Complexity: O(1).
    public int[] ProductExceptSelfConstantSpace(int[] nums)
    {
        int n = nums.Length;
        int[] answer = new int[n];

        answer[0] = 1;
        for (int i = 1; i < n; i++)
        {
            answer[i] = answer[i - 1] * nums[i - 1];
        }

        int suffix = 1;
        for (int i = n - 1; i >= 0; i--)
        {
            answer[i] *= suffix;
            suffix *= nums[i];
        }

        return answer;
    }
}

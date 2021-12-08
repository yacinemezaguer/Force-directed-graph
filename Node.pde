public class Node implements Comparable{
    int key;
    float position[];
    float velocity[];

    int distances;

    public Node(int key, float x, float y){
        this.key = key;
        this.position = new float[]{x, y};
        this.velocity = new float[]  {0.0, 0.0};
    }

    public int compareTo(Object other) {
        Node n = (Node) other;
        return this.distances - n.distances;
    }
}

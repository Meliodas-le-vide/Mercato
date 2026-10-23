interface MobileOverlayProps {
  isOpen: boolean;
  onClick: () => void;
}
export default function MobileOverlay({ isOpen, onClick }: MobileOverlayProps) {
  return (
    <div
      onClick={onClick}
      className={`fixed inset-0 bg-black/30 backdrop-blur-sm z-40 md:hidden transition-opacity duration-300 ${
        isOpen ? 'opacity-100' : 'opacity-0 pointer-events-none'
      }`}
      aria-hidden="true"
    />
  );
}